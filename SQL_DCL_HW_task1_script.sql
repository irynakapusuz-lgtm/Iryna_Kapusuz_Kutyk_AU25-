---Checking existing roles from pg_roles catalog:
SELECT rolname, rolcanlogin, rolsuper, rolcreatedb, rolcreaterole, rolreplication
FROM pg_roles
ORDER BY rolname;
---Result: postgre is super user and has all privileges;
SELECT
    rolname,
    rolcanlogin,
    rolsuper,
    rolcreatedb,
    rolcreaterole,
    rolreplication,
    rolbypassrls,
    rolconnlimit
FROM pg_roles
ORDER BY rolname;
---Result: only postgres has superuser, createdb, and createrole rights;

---Checking which roles belong to which (role memberships):
SELECT
    pg_get_userbyid(roleid)  AS role_name,
    pg_get_userbyid(member)  AS member_name
FROM pg_auth_members
ORDER BY role_name, member_name;
---Result: only system roles have memberships,no extra privileges;

--- Table-level privileges.Checking who owns which table:
SELECT
    schemaname,
    tablename,
    tableowner
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
---Result: tableowner for all tables is postgres;

---Which roles have SELECT/INSERT/UPDATE/DELETE on these tables;
SELECT
    table_schema,
    table_name,
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
ORDER BY table_name, grantee, privilege_type;
---Result: Only postgres has privileges on all tables

---Checking for existing Row-Level Security:
SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    c.relrowsecurity,
    c.relforcerowsecurity
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind = 'r'
ORDER BY c.relname;
---Result: No Row-Level Security anywhere, all rows are available.

---Database-level settings like connection limits or authentication methods:
SELECT
    datname,
    pg_get_userbyid(datdba) AS owner,
    datallowconn,
    datconnlimit,
    datistemplate,
    encoding
FROM pg_database
WHERE datname = 'dvdrental1';
---Result: only postgres superuser can connect and log in to the dvdrental1 database
