#!/bin/bash

# Настройки подключения
HOST="localhost"
PORT="5433"
USER="postgres"
DB="itmo_db"
PGBENCH_CMD="pgbench -h $HOST -p $PORT -n -f trigger_test.sql -c 20 -j 4 -T 60 -U $USER $DB"
PSQL_CMD="psql -h $HOST -p $PORT -U $USER -d $DB"

# Формируем красивую шапку файла отчета
echo "=====================================================" > benchmark_results.txt
echo "    ОТЧЕТ О НАГРУЗОЧНОМ ТЕСТИРОВАНИИ (PGBENCH)       " >> benchmark_results.txt
echo "=====================================================" >> benchmark_results.txt
echo "Дата: $(date)" >> benchmark_results.txt
echo "Параметры: 20 клиентов, 4 потока, 60 секунд" >> benchmark_results.txt
echo "База данных: $DB (Схема: itmo_bd)" >> benchmark_results.txt
echo "=====================================================" >> benchmark_results.txt
echo "" >> benchmark_results.txt

# Функция для запуска теста, чтобы не дублировать bash-код
run_test() {
    local lang_name=$1
    local sql_code=$2

    echo "[$lang_name] 1. Установка триггера..."
    $PSQL_CMD -c "$sql_code" > /dev/null 2>&1

    echo "[$lang_name] 2. Полный сброс кэшей (Перезапуск Docker)..."
    docker restart pg_multilang > /dev/null
    sleep 5 # Ждем, пока база поднимется после рестарта

    echo "[$lang_name] 3. Запуск pgbench на 60 секунд..."
    echo "--- Триггер: $lang_name ---" >> benchmark_results.txt
    $PGBENCH_CMD | grep -E "actually processed|failed transactions|latency average|tps =" >> benchmark_results.txt
    echo "" >> benchmark_results.txt
    echo "[$lang_name] Готово!"
    echo "-----------------------------------"
}

echo "Начинаем тестирование 4 языков..."

# 1. C (Native)
run_test "C (Native)" "
SET search_path TO itmo_bd, public;
DROP TRIGGER IF EXISTS trg_passport ON itmo_bd.person_citizen;
CREATE OR REPLACE FUNCTION generate_passport_c() RETURNS TRIGGER AS 'passport_c', 'generate_passport_c' LANGUAGE C STRICT;
CREATE TRIGGER trg_passport BEFORE UPDATE OF country_id ON itmo_bd.person_citizen FOR EACH ROW EXECUTE FUNCTION generate_passport_c();
"

# 2. PL/Python
run_test "PL/Python" "
SET search_path TO itmo_bd, public;
DROP TRIGGER IF EXISTS trg_passport ON itmo_bd.person_citizen;
CREATE OR REPLACE FUNCTION generate_passport_py() RETURNS TRIGGER AS \$\$
    import hashlib
    plan_p = plpy.prepare('SELECT name, surname FROM itmo_bd.person WHERE id = \$1', ['bigint'])
    res_p = plpy.execute(plan_p, [TD['new']['person_id']])[0]
    plan_c = plpy.prepare('SELECT name FROM itmo_bd.country WHERE id = \$1', ['bigint'])
    res_c = plpy.execute(plan_c, [TD['new']['country_id']])[0]
    base_string = res_p['name'] + res_p['surname'] + res_c['name']
    for i in range(1, 1001):
        base_string = hashlib.md5((base_string + str(i)).encode('utf-8')).hexdigest()
    TD['new']['passport_code'] = base_string
    return 'MODIFY'
\$\$ LANGUAGE plpython3u;
CREATE TRIGGER trg_passport BEFORE UPDATE OF country_id ON itmo_bd.person_citizen FOR EACH ROW EXECUTE FUNCTION generate_passport_py();
"

# 3. PL/Perl
run_test "PL/Perl" "
SET search_path TO itmo_bd, public;
DROP TRIGGER IF EXISTS trg_passport ON itmo_bd.person_citizen;
CREATE OR REPLACE FUNCTION generate_passport_perl() RETURNS TRIGGER AS \$\$
    use Digest::MD5 qw(md5_hex);
    my \$p_id = \$_TD->{new}{person_id};
    my \$c_id = \$_TD->{new}{country_id};
    my \$p_rv = spi_exec_query('SELECT name, surname FROM itmo_bd.person WHERE id = ' . \$p_id);
    my \$c_rv = spi_exec_query('SELECT name FROM itmo_bd.country WHERE id = ' . \$c_id);
    my \$base_string = \$p_rv->{rows}[0]->{name} . \$p_rv->{rows}[0]->{surname} . \$c_rv->{rows}[0]->{name};
    for my \$i (1..1000) { \$base_string = md5_hex(\$base_string . \$i); }
    \$_TD->{new}{passport_code} = \$base_string;
    return 'MODIFY';
\$\$ LANGUAGE plperl;
CREATE TRIGGER trg_passport BEFORE UPDATE OF country_id ON itmo_bd.person_citizen FOR EACH ROW EXECUTE FUNCTION generate_passport_perl();
"

# 4. PL/pgSQL
run_test "PL/pgSQL" "
SET search_path TO itmo_bd, public;
DROP TRIGGER IF EXISTS trg_passport ON itmo_bd.person_citizen;
CREATE OR REPLACE FUNCTION generate_passport_plpgsql() RETURNS TRIGGER AS \$\$
DECLARE
    p_name TEXT; p_surname TEXT; c_name TEXT; base_string TEXT;
BEGIN
    SELECT name, surname INTO p_name, p_surname FROM itmo_bd.person WHERE id = NEW.person_id;
    SELECT name INTO c_name FROM itmo_bd.country WHERE id = NEW.country_id;
    base_string := p_name || p_surname || c_name;
    FOR i IN 1..1000 LOOP
        base_string := md5(base_string || i::TEXT);
    END LOOP;
    NEW.passport_code := base_string;
    RETURN NEW;
END;
\$\$ LANGUAGE plpgsql;
CREATE TRIGGER trg_passport BEFORE UPDATE OF country_id ON itmo_bd.person_citizen FOR EACH ROW EXECUTE FUNCTION generate_passport_plpgsql();
"

echo "====================================================="
echo "Все тесты завершены! Итоговый отчет:"
echo "====================================================="
cat benchmark_results.txt