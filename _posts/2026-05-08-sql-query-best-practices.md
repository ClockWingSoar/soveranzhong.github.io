# SQL查询实战：从基础到性能优化全攻略

## 情境与背景

SQL是数据库操作的基础语言，作为高级DevOps/SRE工程师，在日常运维中经常需要编写SQL进行数据查询、统计和运维操作。本博客详细介绍常用SQL查询场景、性能优化技巧和实战案例，帮助你全面掌握SQL查询技能。

## 一、基础查询

### 1.1 简单查询

**基础SELECT查询**：

```sql
-- 查询所有列
SELECT * FROM users;

-- 查询指定列
SELECT id, username, email FROM users;

-- 带条件查询
SELECT id, name, status
FROM orders
WHERE status = 'completed'
  AND created_at > '2024-01-01';
```

### 1.2 条件查询

**WHERE子句常用操作符**：

```sql
-- 比较运算符
SELECT * FROM products WHERE price > 100;
SELECT * FROM users WHERE age >= 18 AND age <= 60;

-- IN查询（批量匹配）
SELECT * FROM orders
WHERE order_id IN (1001, 1002, 1003, 1004, 1005);

-- LIKE模糊查询
SELECT * FROM users
WHERE email LIKE '%@gmail.com';

SELECT * FROM products
WHERE name LIKE 'iPhone%';

-- BETWEEN范围查询
SELECT * FROM orders
WHERE created_at BETWEEN '2024-01-01' AND '2024-12-31';
```

### 1.3 排序和限制

**ORDER BY和LIMIT**：

```sql
-- 单字段排序
SELECT * FROM products
ORDER BY price DESC;

-- 多字段排序
SELECT * FROM orders
ORDER BY status ASC, created_at DESC;

-- 分页查询（LIMIT OFFSET）
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 10 OFFSET 0;  -- 第1页

SELECT * FROM users
ORDER BY created_at DESC
LIMIT 10 OFFSET 10;  -- 第2页

-- MySQL分页语法
SELECT * FROM users
ORDER BY created_at DESC
LIMIT 10, 10;  -- 从第10行开始取10行
```

## 二、关联查询

### 2.1 JOIN类型

**JOIN类型对比**：

```sql
-- INNER JOIN（内连接）
SELECT o.id, o.order_no, u.username, u.email
FROM orders o
INNER JOIN users u ON o.user_id = u.id;

-- LEFT JOIN（左外连接）
SELECT u.id, u.username, o.order_count
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) as order_count
    FROM orders
    GROUP BY user_id
) o ON u.id = o.user_id;

-- RIGHT JOIN（右外连接）
SELECT d.dept_name, e.emp_name
FROM departments d
RIGHT JOIN employees e ON d.id = e.dept_id;

-- FULL OUTER JOIN（完全外连接）
SELECT COALESCE(u.id, o.user_id) as id,
       u.name, o.order_no
FROM users u
FULL OUTER JOIN orders o ON u.id = o.user_id;
```

### 2.2 多表关联

**三表关联查询**：

```sql
-- 多表关联
SELECT o.id, o.order_no, u.username, p.product_name, oi.quantity, oi.price
FROM orders o
INNER JOIN users u ON o.user_id = u.id
INNER JOIN order_items oi ON o.id = oi.order_id
INNER JOIN products p ON oi.product_id = p.id
WHERE o.status = 'completed'
  AND o.created_at >= '2024-01-01';
```

### 2.3 自关联

**自关联查询**：

```sql
-- 员工表自关联（查询上级）
SELECT e.emp_name as employee,
       m.emp_name as manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.id;

-- 分类表自关联（查询父分类）
SELECT c.category_name,
       p.category_name as parent_category
FROM categories c
LEFT JOIN categories p ON c.parent_id = p.id;
```

## 三、聚合统计

### 3.1 聚合函数

**常用聚合函数**：

```sql
-- COUNT计数
SELECT COUNT(*) FROM orders;
SELECT COUNT(DISTINCT user_id) FROM orders;

-- SUM求和
SELECT SUM(amount) FROM orders WHERE status = 'completed';

-- AVG平均值
SELECT AVG(price) FROM products WHERE category_id = 1;

-- MAX最大值
SELECT MAX(price) FROM products;

-- MIN最小值
SELECT MIN(created_at) FROM orders;
```

### 3.2 分组统计

**GROUP BY使用**：

```sql
-- 单字段分组
SELECT category_id,
       COUNT(*) as product_count,
       AVG(price) as avg_price,
       MAX(price) as max_price,
       MIN(price) as min_price
FROM products
GROUP BY category_id;

-- 多字段分组
SELECT YEAR(created_at) as year,
       MONTH(created_at) as month,
       COUNT(*) as order_count,
       SUM(amount) as total_amount
FROM orders
GROUP BY YEAR(created_at), MONTH(created_at);

-- HAVING过滤分组结果
SELECT user_id,
       COUNT(*) as order_count,
       SUM(amount) as total_amount
FROM orders
WHERE status = 'completed'
GROUP BY user_id
HAVING COUNT(*) > 10
   AND SUM(amount) > 1000;
```

### 3.3 条件统计

**CASE WHEN条件统计**：

```sql
-- 条件计数
SELECT
    COUNT(*) as total_orders,
    COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled
FROM orders;

-- 条件求和
SELECT
    SUM(amount) as total_amount,
    SUM(CASE WHEN payment_method = 'card' THEN amount ELSE 0 END) as card_amount,
    SUM(CASE WHEN payment_method = 'cash' THEN amount ELSE 0 END) as cash_amount
FROM orders;
```

## 四、子查询

### 4.1 标量子查询

**返回单个值的子查询**：

```sql
-- 在WHERE中使用
SELECT * FROM products
WHERE price > (SELECT AVG(price) FROM products);

-- 在SELECT中使用
SELECT p.name,
       p.price,
       (SELECT AVG(price) FROM products WHERE category_id = p.category_id) as category_avg
FROM products p;
```

### 4.2 表子查询

**返回结果集的子查询**：

```sql
-- 在FROM中使用
SELECT *
FROM (
    SELECT user_id, COUNT(*) as order_count
    FROM orders
    GROUP BY user_id
) as order_stats
WHERE order_count > 5;

-- 在IN中使用
SELECT * FROM users
WHERE id IN (
    SELECT DISTINCT user_id
    FROM orders
    WHERE created_at > '2024-01-01'
);
```

### 4.3 EXISTS子查询

**EXISTS判断**：

```sql
-- 查询有订单的用户
SELECT * FROM users u
WHERE EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);

-- 查询没有订单的用户
SELECT * FROM users u
WHERE NOT EXISTS (
    SELECT 1 FROM orders o WHERE o.user_id = u.id
);
```

## 五、数据操作

### 5.1 INSERT插入

**插入数据**：

```sql
-- 插入单行
INSERT INTO users (username, email, password, created_at)
VALUES ('testuser', 'test@example.com', 'hashed_password', NOW());

-- 插入多行
INSERT INTO products (name, price, category_id, created_at)
VALUES
    ('Product A', 99.99, 1, NOW()),
    ('Product B', 149.99, 1, NOW()),
    ('Product C', 299.99, 2, NOW());

-- 从查询结果插入
INSERT INTO order_stats (user_id, order_count)
SELECT user_id, COUNT(*)
FROM orders
WHERE status = 'completed'
GROUP BY user_id;
```

### 5.2 UPDATE更新

**更新数据**：

```sql
-- 条件更新
UPDATE users
SET email = 'newemail@example.com', updated_at = NOW()
WHERE id = 123;

-- 批量更新
UPDATE products
SET price = price * 0.9,
    updated_at = NOW()
WHERE category_id = 1
  AND price > 100;

-- 多字段更新
UPDATE orders
SET status = 'cancelled',
    cancel_reason = '用户主动取消',
    cancelled_at = NOW()
WHERE status = 'pending'
  AND created_at < DATE_SUB(NOW(), INTERVAL 7 DAY);
```

### 5.3 DELETE删除

**删除数据**：

```sql
-- 条件删除
DELETE FROM orders
WHERE status = 'cancelled'
  AND created_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);

-- 批量删除
DELETE FROM order_items
WHERE order_id IN (
    SELECT id FROM orders WHERE status = 'cancelled'
);

-- 清空表（慎用）
TRUNCATE TABLE temp_data;
```

## 六、性能优化

### 6.1 索引优化

**索引使用原则**：

```sql
-- 创建单列索引
CREATE INDEX idx_user_id ON orders(user_id);

-- 创建复合索引（注意字段顺序）
CREATE INDEX idx_status_created ON orders(status, created_at);

-- 创建唯一索引
CREATE UNIQUE INDEX idx_order_no ON orders(order_no);

-- 查看查询执行计划
EXPLAIN SELECT * FROM orders WHERE user_id = 123;

EXPLAIN SELECT o.*, u.username
FROM orders o
INNER JOIN users u ON o.user_id = u.id
WHERE o.status = 'completed';
```

### 6.2 查询优化技巧

**优化原则**：

```sql
-- ❌ 避免使用SELECT *
SELECT id, username, email FROM users WHERE id = 123;

-- ❌ 避免在索引列上使用函数
-- 错误写法
SELECT * FROM orders WHERE YEAR(created_at) = 2024;
-- 正确写法
SELECT * FROM orders WHERE created_at >= '2024-01-01' AND created_at < '2025-01-01';

-- ❌ 避免使用OR导致索引失效
-- 错误写法
SELECT * FROM users WHERE id = 123 OR email = 'test@example.com';
-- 正确写法（使用UNION）
SELECT * FROM users WHERE id = 123
UNION
SELECT * FROM users WHERE email = 'test@example.com';
```

### 6.3 分页优化

**大表分页查询**：

```sql
-- ❌ 低效分页（OFFSET过大时）
SELECT * FROM orders
ORDER BY id
LIMIT 1000000, 10;

-- ✅ 高效分页（基于ID）
SELECT * FROM orders
WHERE id > 1000000
ORDER BY id
LIMIT 10;

-- ✅ 高效分页（游标方式）
SELECT * FROM orders
WHERE created_at > '2024-01-01'
ORDER BY created_at
LIMIT 10;
```

## 七、实战运维场景

### 7.1 数据统计场景

**常用统计SQL**：

```sql
-- 日活用户统计
SELECT DATE(login_time) as date,
       COUNT(DISTINCT user_id) as dau
FROM user_logs
WHERE login_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(login_time);

-- 订单漏斗分析
SELECT
    COUNT(CASE WHEN step = 1 THEN 1 END) as step1_views,
    COUNT(CASE WHEN step = 2 THEN 1 END) as step2_carts,
    COUNT(CASE WHEN step = 3 THEN 1 END) as step3_orders,
    COUNT(CASE WHEN step = 4 THEN 1 END) as step4_payments
FROM user_behavior;

-- 用户留存分析
SELECT
    DATE(first_login) as cohort_date,
    COUNT(DISTINCT user_id) as cohort_size,
    COUNT(DISTINCT CASE WHEN days_since_login = 1 THEN user_id END) as d1_retention,
    COUNT(DISTINCT CASE WHEN days_since_login = 7 THEN user_id END) as d7_retention
FROM user_login_stats
GROUP BY DATE(first_login);
```

### 7.2 数据清理场景

**运维数据清理**：

```sql
-- 清理30天前的日志数据
DELETE FROM operation_logs
WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY);

-- 清理过期token
DELETE FROM user_tokens
WHERE expires_at < NOW();

-- 归档历史订单
INSERT INTO orders_archive
SELECT * FROM orders
WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 YEAR);

DELETE FROM orders
WHERE created_at < DATE_SUB(NOW(), INTERVAL 2 YEAR);
```

### 7.3 数据修复场景

**数据修复SQL**：

```sql
-- 修复缺失数据
UPDATE orders o
SET user_id = (
    SELECT user_id FROM users WHERE email = o.customer_email
)
WHERE user_id IS NULL;

-- 批量更新状态
UPDATE orders
SET status = 'completed',
    completed_at = updated_at
WHERE status = 'paid'
  AND updated_at < DATE_SUB(NOW(), INTERVAL 7 DAY);

-- 修复关联数据
UPDATE order_items oi
SET product_name = (
    SELECT name FROM products WHERE id = oi.product_id
)
WHERE product_name IS NULL;
```

## 八、面试1分钟精简版（直接背）

**完整版**：

常用SQL查询场景包括：基础的条件查询用WHERE；多表关联用JOIN；数据统计用GROUP BY加聚合函数；分页查询用LIMIT；批量更新和删除用IN；复杂查询用子查询。性能优化要注意：避免SELECT *、合理使用索引、用EXPLAIN分析执行计划、避免在索引列上做函数操作。

**30秒超短版**：

WHERE条件、JOIN关联、GROUP BY统计、LIMIT分页、子查询复杂查询。性能优化：避免SELECT *，用索引，用EXPLAIN。

## 九、总结

### 9.1 SQL命令速查

| 操作 | 命令 | 示例 |
|:----:|------|------|
| **查询** | SELECT | SELECT * FROM table WHERE condition |
| **插入** | INSERT | INSERT INTO table VALUES(...) |
| **更新** | UPDATE | UPDATE table SET col=val WHERE... |
| **删除** | DELETE | DELETE FROM table WHERE... |
| **关联** | JOIN | SELECT * FROM a JOIN b ON a.id=b.id |
| **统计** | GROUP BY | GROUP BY col HAVING count>10 |

### 9.2 优化口诀

```
查询避免SELECT *，索引字段不加函数，
OR改UNION效率高，分页OFFSET要不得，
EXPLAIN分析执行计划，索引遵循最左前缀。
```

### 9.3 最佳实践清单

```yaml
best_practices:
  - "永远加WHERE条件，避免全表扫描"
  - "SELECT指定列名，避免SELECT *"
  - "合理创建索引，遵循最左前缀原则"
  - "批量操作用事务，保证数据一致性"
  - "定期清理历史数据，保持表数据量合理"
  - "重要操作先备份，测试环境验证后再执行"
```

> **参考链接**：[SRE运维面试题全解析：从理论到实践（第二部分）]({% post_url 2026-04-15-sre-interview-questions-part2 %})