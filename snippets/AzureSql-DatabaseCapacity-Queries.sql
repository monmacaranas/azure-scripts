/*
Azure SQL Database capacity troubleshooting snippets.
Use when investigating "database has reached its size quota" or unexpected database growth.
Read-only queries only.
*/

-- Current database size by file
SELECT
    name AS LogicalFileName,
    type_desc,
    size * 8.0 / 1024 AS SizeMB,
    max_size,
    growth
FROM sys.database_files;

-- Approximate space used by database objects
SELECT
    SUM(reserved_page_count) * 8.0 / 1024 AS ReservedMB,
    SUM(used_page_count) * 8.0 / 1024 AS UsedMB
FROM sys.dm_db_partition_stats;

-- Largest tables by reserved space
SELECT TOP (25)
    s.name AS SchemaName,
    t.name AS TableName,
    SUM(ps.reserved_page_count) * 8.0 / 1024 AS ReservedMB,
    SUM(ps.used_page_count) * 8.0 / 1024 AS UsedMB
FROM sys.dm_db_partition_stats ps
JOIN sys.tables t ON ps.object_id = t.object_id
JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY s.name, t.name
ORDER BY ReservedMB DESC;
