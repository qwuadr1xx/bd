#include "postgres.h"
#include "fmgr.h"
#include "executor/spi.h"
#include "commands/trigger.h"
#include "utils/builtins.h"
#include "utils/rel.h"
#include "common/md5.h"

PG_MODULE_MAGIC;

// Глобальные переменные для хранения кэшированных планов
static SPIPlanPtr plan_person = NULL;
static SPIPlanPtr plan_country = NULL;

PG_FUNCTION_INFO_V1(generate_passport_c);

Datum generate_passport_c(PG_FUNCTION_ARGS) {
    TriggerData *trigdata = (TriggerData *) fcinfo->context;
    HeapTuple   rettuple;
    TupleDesc   tupdesc;
    int         ret;
    bool        isnull;

    if (!CALLED_AS_TRIGGER(fcinfo))
        elog(ERROR, "generate_passport_c: not called by trigger manager");

    rettuple = trigdata->tg_newtuple;
    tupdesc = trigdata->tg_relation->rd_att;

    if ((ret = SPI_connect()) < 0)
        elog(ERROR, "generate_passport_c: SPI_connect returned %d", ret);

    // Получаем ID персоны и страны из NEW
    Datum person_id_datum = SPI_getbinval(rettuple, tupdesc, 1, &isnull);
    Datum country_id_datum = SPI_getbinval(rettuple, tupdesc, 2, &isnull);

    Oid argtypes[1] = { INT8OID }; // Тип BIGINT
    char nulls[1] = { ' ' };       // Параметры не NULL
    char *p_name = "", *p_surname = "", *c_name = "";

    // ---------------------------------------------------------
    // ОПТИМИЗАЦИЯ: Кэширование планов (Prepared Statements)
    // ---------------------------------------------------------
    if (plan_person == NULL) {
        SPIPlanPtr p = SPI_prepare("SELECT name, surname FROM itmo_bd.person WHERE id = $1", 1, argtypes);
        if (p == NULL) elog(ERROR, "generate_passport_c: SPI_prepare for person failed");
        plan_person = SPI_keepplan(p);
    }
    
    if (plan_country == NULL) {
        SPIPlanPtr p = SPI_prepare("SELECT name FROM itmo_bd.country WHERE id = $1", 1, argtypes);
        if (p == NULL) elog(ERROR, "generate_passport_c: SPI_prepare for country failed");
        plan_country = SPI_keepplan(p);
    }

    // ---------------------------------------------------------
    // Выполнение кэшированных планов
    // ---------------------------------------------------------
    Datum p_values[1] = { person_id_datum };
    ret = SPI_execute_plan(plan_person, p_values, nulls, true, 1);
    if (ret > 0 && SPI_processed > 0) {
        p_name = SPI_getvalue(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1);
        p_surname = SPI_getvalue(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 2);
    }

    Datum c_values[1] = { country_id_datum };
    ret = SPI_execute_plan(plan_country, c_values, nulls, true, 1);
    if (ret > 0 && SPI_processed > 0) {
        c_name = SPI_getvalue(SPI_tuptable->vals[0], SPI_tuptable->tupdesc, 1);
    }

    // Закрываем контекст, но планы (SPI_keepplan) остаются в памяти!
    SPI_finish();

    // ---------------------------------------------------------
    // Тяжелая бизнес-логика (1000 итераций MD5)
    // ---------------------------------------------------------
    char base_string[2048];
    snprintf(base_string, sizeof(base_string), "%s%s%s", 
             p_name ? p_name : "", 
             p_surname ? p_surname : "", 
             c_name ? c_name : "");

    char buffer[2048];
    char hexbuf[MD5_PASSWD_LEN + 1];
    const char *errstr = NULL;
    char *current_hash = base_string;

    for (int i = 1; i <= 1000; i++) {
        snprintf(buffer, sizeof(buffer), "%s%d", current_hash, i);
        if (pg_md5_hash(buffer, strlen(buffer), hexbuf, &errstr) == false) {
             elog(ERROR, "generate_passport_c: MD5 error");
        }
        current_hash = hexbuf; 
    }

    // ---------------------------------------------------------
    // Модификация записи NEW
    // ---------------------------------------------------------
    Datum new_values[3];
    bool new_nulls[3] = {false, false, false};
    bool new_replaces[3] = {false, false, true}; // Изменяем только 3-ю колонку (passport_code)

    new_values[2] = CStringGetTextDatum(current_hash);
    
    // Возвращаем измененный кортеж обратно в движок Postgres
    rettuple = heap_modify_tuple(rettuple, tupdesc, new_values, new_nulls, new_replaces);

    return PointerGetDatum(rettuple);
}
