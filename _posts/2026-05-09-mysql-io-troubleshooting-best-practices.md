# MySQL磁盘IO高问题排查：从现象到根因的完整指南

## 情境与背景

在生产环境中，经常会遇到CPU和内存使用率很低，但磁盘IO很高的情况。这通常是IO密集型瓶颈的典型表现，需要系统性地排查才能找到根本原因。

## 一、问题定位：确认是MySQL导致的IO高

### 1.1 系统层面检查

**磁盘IO监控**：

```markdown
## 第一步：确认IO来源

**系统命令**：

```bash
# 查看磁盘IO统计
iostat -x 1 10

# 查看进程IO使用
iotop

# 查看磁盘使用情况
df -h

# 查看磁盘读写速度
dd if=/dev/zero of=/tmp/test bs=1G count=1 oflag=direct
```

**关键指标**：

```yaml
iostat_metrics:
  rMB/s: "每秒读取MB数"
  wMB/s: "每秒写入MB数"
  %util: "设备繁忙程度"
  avgqu-sz: "平均队列长度"
  await: "平均等待时间(ms)"
```

**确认MySQL进程**：

```bash
# 查找MySQL进程ID
ps aux | grep mysqld

# 查看MySQL进程的IO使用
iotop -p <pid>
```
```

### 1.2 MySQL状态检查

**MySQL状态查询**：

```markdown
## 第二步：检查MySQL状态

**连接状态**：

```bash
# 查看当前连接
SHOW PROCESSLIST;

# 查看完整连接信息
SHOW FULL PROCESSLIST;

# 查看连接数
SHOW STATUS LIKE 'Threads_%';
```

**关键状态变量**：

```yaml
mysql_status:
  Threads_connected: "当前连接数"
  Threads_running: "活跃连接数"
  Questions: "总查询数"
  Queries: "总SQL语句数"
  Innodb_buffer_pool_reads: "从磁盘读取的页数"
  Innodb_buffer_pool_read_requests: "缓冲池读取请求数"
```
```

## 二、慢查询分析

### 2.1 慢查询日志配置

**启用慢查询日志**：

```markdown
## 第三步：分析慢查询

**配置慢查询日志**：

```bash
# 查看当前配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';

# 临时启用慢查询日志
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 1;
SET GLOBAL log_queries_not_using_indexes = ON;
```

**my.cnf配置**：

```yaml
slow_query_config:
  slow_query_log: "ON"
  slow_query_log_file: "/var/log/mysql/slow.log"
  long_query_time: 1
  log_queries_not_using_indexes: "ON"
  log_slow_admin_statements: "ON"
```
```

### 2.2 慢查询日志分析

**分析工具**：

```markdown
**慢查询分析工具**：

```bash
# 使用mysqldumpslow分析
mysqldumpslow -s t /var/log/mysql/slow.log

# 使用pt-query-digest分析（Percona Toolkit）
pt-query-digest /var/log/mysql/slow.log

# 查看前10条最慢查询
mysqldumpslow -s t -t 10 /var/log/mysql/slow.log
```

**关键分析维度**：

```yaml
slow_query_analysis:
  Query_time: "查询耗时"
  Lock_time: "锁等待时间"
  Rows_sent: "返回行数"
  Rows_examined: "检查行数"
  Full_scan: "是否全表扫描"
  Full_join: "是否全表连接"
```
```

## 三、执行计划分析

### 3.1 EXPLAIN分析

**执行计划详解**：

```markdown
## 第四步：分析执行计划

**EXPLAIN使用**：

```sql
EXPLAIN SELECT * FROM orders WHERE user_id = 12345;

EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 12345;
```

**执行计划字段**：

```yaml
explain_columns:
  id: "查询ID"
  select_type: "查询类型"
  table: "表名"
  type: "访问类型"
  possible_keys: "可能使用的索引"
  key: "实际使用的索引"
  key_len: "索引长度"
  ref: "与索引比较的列"
  rows: "预计扫描行数"
  Extra: "额外信息"
```

**type字段解读**：

```yaml
type_interpretation:
  ALL: "全表扫描（最差）"
  index: "索引全扫描"
  range: "范围扫描"
  ref: "非唯一索引扫描"
  eq_ref: "唯一索引扫描"
  const: "常量查询（最优）"
```

**Extra字段解读**：

```yaml
extra_interpretation:
  Using index: "使用覆盖索引"
  Using where: "使用WHERE条件"
  Using filesort: "使用文件排序（性能差）"
  Using temporary: "使用临时表（性能差）"
  Using join buffer: "使用连接缓冲"
```
```

### 3.2 索引失效场景

**常见索引失效原因**：

```markdown
## 索引失效场景

**索引失效原因**：

```yaml
index_failure_cases:
  - "SELECT * FROM users WHERE name LIKE '%test%'"  # 前缀模糊匹配
  - "SELECT * FROM users WHERE age + 1 = 30"        # 列上有函数运算
  - "SELECT * FROM users WHERE status = 1 OR age > 18" # OR条件（只有一个条件有索引）
  - "SELECT * FROM users WHERE id IN (SELECT id FROM orders)" # 子查询
  - "SELECT * FROM users WHERE name = 'test' COLLATE utf8_bin" # 字符集不一致
  - "SELECT * FROM users WHERE created_at > '2024-01-01' AND status = 1" # 索引顺序问题
```

**复合索引最左前缀原则**：

```yaml
composite_index_principle:
  index: "idx_name_age_status (name, age, status)"
  
  valid_queries:
    - "WHERE name = 'test'"
    - "WHERE name = 'test' AND age = 18"
    - "WHERE name = 'test' AND age = 18 AND status = 1"
    
  invalid_queries:
    - "WHERE age = 18"                 # 不满足最左前缀
    - "WHERE age = 18 AND status = 1"  # 不满足最左前缀
    - "WHERE status = 1"               # 不满足最左前缀
```
```

## 四、InnoDB状态分析

### 4.1 缓冲池分析

**缓冲池状态**：

```markdown
## 第五步：分析InnoDB状态

**缓冲池命中率**：

```sql
-- 计算缓冲池命中率
SELECT 
  (1 - (sum(innodb_buffer_pool_reads) / sum(innodb_buffer_pool_read_requests))) * 100 AS hit_rate
FROM information_schema.global_status;
```

**缓冲池配置**：

```yaml
buffer_pool_config:
  innodb_buffer_pool_size:
    description: "缓冲池大小"
    recommendation: "物理内存的50-70%"
    
  innodb_buffer_pool_instances:
    description: "缓冲池实例数"
    recommendation: "每4GB一个实例"
    
  innodb_buffer_pool_dump_at_shutdown:
    description: "关闭时保存缓冲池"
    recommendation: "开启"
    
  innodb_buffer_pool_load_at_startup:
    description: "启动时加载缓冲池"
    recommendation: "开启"
```

**缓冲池状态查询**：

```sql
SHOW ENGINE INNODB STATUS;

-- 查看缓冲池状态
SELECT * FROM information_schema.INNODB_BUFFER_POOL_STATS;
```
```

### 4.2 日志刷盘分析

**日志刷盘配置**：

```markdown
**日志刷盘策略**：

```yaml
log_flush_config:
  innodb_flush_log_at_trx_commit:
    description: "日志刷盘策略"
    values:
      - "0: 每秒刷盘（性能最好，可能丢失数据）"
      - "1: 每次事务提交刷盘（最安全，性能最差）"
      - "2: 每次事务提交写入OS缓存，每秒刷盘（平衡）"
    
  innodb_log_file_size:
    description: "重做日志文件大小"
    recommendation: "256MB-2GB"
    
  innodb_log_buffer_size:
    description: "日志缓冲区大小"
    recommendation: "16-64MB"
    
  sync_binlog:
    description: "binlog刷盘策略"
    values:
      - "0: 由OS决定"
      - "1: 每次事务提交刷盘"
```

**刷盘频率分析**：

```sql
-- 查看日志刷盘统计
SHOW STATUS LIKE 'Innodb_os_log%';

-- Innodb_os_log_written: 写入日志字节数
-- Innodb_os_log_fsyncs: fsync次数
```
```

### 4.3 磁盘写入分析

**写入热点分析**：

```markdown
**写入操作分析**：

```sql
-- 查看写入统计
SHOW STATUS LIKE 'Com_insert%';
SHOW STATUS LIKE 'Com_update%';
SHOW STATUS LIKE 'Com_delete%';

-- 查看InnoDB写入统计
SHOW STATUS LIKE 'Innodb_data_written';
SHOW STATUS LIKE 'Innodb_pages_written';
```

**临时表分析**：

```sql
-- 查看临时表使用情况
SHOW GLOBAL STATUS LIKE 'Created_tmp%';

-- 临时表配置
SHOW VARIABLES LIKE 'tmp_table_size';
SHOW VARIABLES LIKE 'max_heap_table_size';
```
```

## 五、常见根因与解决方案

### 5.1 全表扫描

**问题与解决方案**：

```markdown
## 常见根因分析

### 根因1：全表扫描

**现象**：
```yaml
symptoms:
  - "type = ALL"
  - "rows_examined 远大于 rows_sent"
  - "Extra: Using where"
```

**原因**：
```yaml
causes:
  - "缺少索引"
  - "索引失效"
  - "查询条件不适合索引"
```

**解决方案**：
```yaml
solutions:
  - "创建合适的索引"
  - "优化查询条件"
  - "使用覆盖索引"
  
  example:
    problem: "SELECT * FROM orders WHERE user_id = 12345"
    solution: "CREATE INDEX idx_user_id ON orders(user_id)"
```
```

### 5.2 索引失效

**问题与解决方案**：

```markdown
### 根因2：索引失效

**现象**：
```yaml
symptoms:
  - "key = NULL"
  - "possible_keys 有值但 key 为NULL"
```

**原因**：
```yaml
causes:
  - "使用LIKE '%xxx'"
  - "列上有函数运算"
  - "OR条件不满足"
  - "字符集不一致"
```

**解决方案**：
```yaml
solutions:
  - "避免前缀模糊匹配"
  - "避免在列上使用函数"
  - "优化OR条件"
  - "统一字符集"
  
  example:
    problem: "SELECT * FROM users WHERE DATE(created_at) = '2024-01-01'"
    solution: "SELECT * FROM users WHERE created_at >= '2024-01-01' AND created_at < '2024-01-02'"
```
```

### 5.3 文件排序

**问题与解决方案**：

```markdown
### 根因3：文件排序

**现象**：
```yaml
symptoms:
  - "Extra: Using filesort"
  - "ORDER BY 字段没有索引"
```

**原因**：
```yaml
causes:
  - "ORDER BY 字段没有索引"
  - "ORDER BY 多个字段，索引顺序不一致"
```

**解决方案**：
```yaml
solutions:
  - "创建包含ORDER BY字段的索引"
  - "使用覆盖索引"
  
  example:
    problem: "SELECT * FROM orders WHERE user_id = 12345 ORDER BY create_time DESC"
    solution: "CREATE INDEX idx_user_time ON orders(user_id, create_time DESC)"
```
```

### 5.4 日志刷盘频繁

**问题与解决方案**：

```markdown
### 根因4：日志刷盘频繁

**现象**：
```yaml
symptoms:
  - "高write IO"
  - "Innodb_os_log_fsyncs 频繁"
  - "小事务频繁提交"
```

**原因**：
```yaml
causes:
  - "innodb_flush_log_at_trx_commit = 1"
  - "sync_binlog = 1"
  - "大量小事务"
```

**解决方案**：
```yaml
solutions:
  - "调整 innodb_flush_log_at_trx_commit = 2"
  - "调整 sync_binlog = 100"
  - "合并小事务"
  
  example:
    before: "每秒1000次提交，每次fsync"
    after: "合并为每秒10次提交，每次fsync"
```
```

### 5.5 数据写入量大

**问题与解决方案**：

```markdown
### 根因5：数据写入量大

**现象**：
```yaml
symptoms:
  - "高write IO"
  - "磁盘使用率持续增长"
  - "大量INSERT/UPDATE操作"
```

**原因**：
```yaml
causes:
  - "批量写入"
  - "频繁更新"
  - "日志表持续写入"
```

**解决方案**：
```yaml
solutions:
  - "使用批量插入"
  - "使用异步写入"
  - "分库分表"
  - "归档历史数据"
  
  example:
    before: "INSERT INTO logs VALUES (...)"
    after: "INSERT INTO logs VALUES (...), (...), (...)"
```
```

## 六、优化方案总结

### 6.1 索引优化

**索引优化策略**：

```markdown
## 优化方案

### 索引优化

```yaml
index_optimization:
  create_index:
    - "为WHERE条件列创建索引"
    - "为ORDER BY列创建索引"
    - "使用复合索引"
    
  drop_index:
    - "删除冗余索引"
    - "删除未使用的索引"
    
  analyze_index:
    - "定期使用ANALYZE TABLE"
    - "检查索引碎片"
```
```

### 6.2 SQL优化

**SQL优化策略**：

```markdown
### SQL优化

```yaml
sql_optimization:
  select_columns:
    - "避免SELECT *"
    - "只查询需要的列"
    
  join_optimization:
    - "使用INNER JOIN替代子查询"
    - "小表驱动大表"
    
  limit_optimization:
    - "避免OFFSET过大"
    - "使用游标分页"
    
  group_by_optimization:
    - "使用索引优化GROUP BY"
    - "避免ORDER BY RAND()"
```
```

### 6.3 配置优化

**配置优化策略**：

```markdown
### 配置优化

```yaml
configuration_optimization:
  memory:
    - "innodb_buffer_pool_size = 物理内存的50-70%"
    - "innodb_log_buffer_size = 64M"
    
  io:
    - "innodb_flush_log_at_trx_commit = 2"
    - "sync_binlog = 100"
    - "innodb_log_file_size = 1G"
    
  connection:
    - "max_connections = 合理值"
    - "wait_timeout = 60"
```
```

### 6.4 架构优化

**架构优化策略**：

```markdown
### 架构优化

```yaml
architecture_optimization:
  read_write_split:
    - "主从复制"
    - "读请求路由到Slave"
    
  sharding:
    - "分库分表"
    - "按业务拆分"
    
  caching:
    - "Redis缓存热点数据"
    - "应用层缓存"
    
  partitioning:
    - "使用分区表"
    - "按时间分区"
```
```

## 七、实战案例

### 7.1 案例：全表扫描导致IO高

**案例描述**：

```markdown
## 实战案例

### 案例1：全表扫描

**问题现象**：
- CPU: 10%
- 内存: 30%
- 磁盘IO: 90%+

**排查过程**：

```yaml
investigation:
  step_1: "iotop确认MySQL进程IO高"
  step_2: "查看慢查询日志"
  step_3: "发现慢查询：SELECT * FROM orders WHERE status = 1"
  step_4: "EXPLAIN分析：type = ALL，全表扫描"
  step_5: "检查索引：status列没有索引"
```

**解决方案**：

```yaml
solution:
  create_index: "CREATE INDEX idx_status ON orders(status)"
  
  result:
    before: "查询耗时5秒，IO高"
    after: "查询耗时<100ms，IO正常"
```
```

### 7.2 案例：日志刷盘导致IO高

**案例描述**：

```markdown
### 案例2：日志刷盘频繁

**问题现象**：
- 每秒大量小事务提交
- write IO持续很高
- innodb_flush_log_at_trx_commit = 1

**排查过程**：

```yaml
investigation:
  step_1: "iostat显示高write IO"
  step_2: "SHOW STATUS LIKE 'Innodb_os_log_fsyncs'"
  step_3: "发现每秒fsync次数超过1000"
  step_4: "检查应用代码：频繁小事务"
```

**解决方案**：

```yaml
solution:
  batch_transactions: "合并小事务为批量操作"
  config_tuning: "innodb_flush_log_at_trx_commit = 2"
  
  result:
    before: "write IO: 50MB/s"
    after: "write IO: 5MB/s"
```
```

## 八、面试1分钟精简版（直接背）

**完整版**：

排查步骤：1. 使用iostat/iotop查看磁盘IO情况，确认是MySQL进程；2. 使用SHOW PROCESSLIST查看当前会话；3. 分析慢查询日志，找出耗时查询；4. 使用EXPLAIN分析执行计划，看是否全表扫描或索引失效；5. 查看InnoDB状态，检查缓冲池命中率、日志刷盘频率；6. 常见根因：全表扫描、索引失效、排序使用filesort、日志刷盘策略不当。优化方案：添加索引、优化SQL、调整innodb_flush_log_at_trx_commit、增加缓存。

**30秒超短版**：

iostat确认IO来源，慢查询日志找问题，EXPLAIN分析执行计划，常见原因：全表扫描、索引失效、filesort、刷盘频繁；优化：加索引、优化SQL、调整配置。

## 九、总结

### 9.1 排查流程总结

```yaml
troubleshooting_flow:
  step_1: "确认IO来源"
    command: "iostat, iotop"
    
  step_2: "检查MySQL状态"
    command: "SHOW PROCESSLIST"
    
  step_3: "分析慢查询"
    command: "mysqldumpslow, pt-query-digest"
    
  step_4: "分析执行计划"
    command: "EXPLAIN"
    
  step_5: "检查InnoDB状态"
    command: "SHOW ENGINE INNODB STATUS"
    
  step_6: "定位根因并优化"
    actions: ["加索引", "优化SQL", "调整配置"]
```

### 9.2 常见根因总结

```yaml
common_causes:
  full_table_scan:
    description: "全表扫描"
    solution: "添加索引"
    
  index_failure:
    description: "索引失效"
    solution: "优化查询条件"
    
  filesort:
    description: "文件排序"
    solution: "创建排序索引"
    
  log_flush:
    description: "日志刷盘频繁"
    solution: "调整刷盘策略"
    
  heavy_write:
    description: "写入量大"
    solution: "批量写入、异步写入"
```

### 9.3 最佳实践清单

```yaml
best_practices:
  monitoring:
    - "监控磁盘IO"
    - "监控慢查询"
    - "设置IO告警"
    
  prevention:
    - "定期检查索引使用情况"
    - "定期分析慢查询日志"
    - "定期优化配置"
    
  optimization:
    - "使用覆盖索引"
    - "避免全表扫描"
    - "优化排序和分组"
```

### 9.4 记忆口诀

```
IO高先看进程，确认MySQL是元凶，
慢查询日志找问题，EXPLAIN分析执行计划，
全表扫描最常见，索引失效是关键，
filesort要优化，刷盘策略调一调，
添加索引加缓存，IO问题解决了。
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})