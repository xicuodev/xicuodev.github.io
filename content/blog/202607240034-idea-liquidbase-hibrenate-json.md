---
date: 2026-07-24T10:34:00+08:00
slug: idea-liquidbase-hibrenate-json
title: IDEA的 liquibase-hibernate 插件处理JSON映射的有效JPA注解
---

liquibase 是 java 生态的一个数据库迁移脚本生成和管理工具。liquibase-hibernate 是 intellij idea 集成的 liquibase 更新日志生成器插件。

对于 jdk 8 + mysql 5.7.8 持久化 json 类型的实用方案，在前面这里简要给出，具体见下面 [jdk8 的方案-原生 jpa 方案](#jdk8-jpa)：

```java
@Convert(converter = JpaMapJsonConverter.class)
@Column(columnDefinition = "json")
private Map<String, String> spec;
```

生成的 SQL 更新日志：

```sql
ALTER TABLE item ADD spec JSON NULL;
```

## jdk 11 的方案

Java 实体类字段：最低支持 jdk 11，使用 jdk 8 的见下。

```java
@JdbcTypeCode(SqlTypes.JSON)
@Convert(converter = JpaMapJsonConverter.class)
private Map<String, String> spec;
```

生成的 SQL 更新日志：

```sql
ALTER TABLE item ADD spec JSON NULL;
```

## jdk 8 的方案

### 原生 jpa 方案 (适合 mysql) {#jdk8-jpa}

用 jpa 标准的 `AttributeConverter` 手动调用 jackson 实现 map 与 string 互转。mysql jdbc 驱动天然支持将 JSON 字符串存入 mysql 5.7.8+ 的 `JSON` 列。

```java
@Converter
public class JpaMapJsonConverter implements AttributeConverter<Map<String, Object>, String> {
  private static final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public String convertToDatabaseColumn(Map<String, Object> attribute) {
    if (attribute == null) {
      return null;
    }
    try {
      return objectMapper.writeValueAsString(attribute);
    } catch (JsonProcessingException e) {
      throw new RuntimeException("JSON 序列化失败: " + e.getMessage(), e);
    }
  }

  @Override
  public Map<String, Object> convertToEntityAttribute(String dbData) {
    if (dbData == null || dbData.trim().isEmpty()) {
      return null;
    }
    try {
      // 必须使用 TypeReference，否则用 Map.class 反序列化出来可能丢失泛型类型
      return objectMapper.readValue(dbData, new TypeReference<Map<String, Object>>() {});
    } catch (JsonProcessingException e) {
      throw new RuntimeException("JSON 反序列化失败: " + e.getMessage(), e);
    }
  }
}
```

```java
@Column(columnDefinition = "json")
@Convert(converter = JpaMapJsonConverter.class)
private Map<String, Object> spec;
```

### hibernate-types 方案 (适合 postgresql)

`@JdbcTypeCode` 需要 hibernate orm 6，但是后者[最低支持 jdk 11](https://hibernate.org/community/integrations/#java)，jdk 8 用不了，替代方案：**Hibernate 5.x + [hibernate-types 库](https://github.com/vladmihalcea/hypersistence-utils) + 手动注明 `@Column(columnDefinition = "json")`**

```xml
<dependency>
    <groupId>org.hibernate</groupId>
    <artifactId>hibernate-core</artifactId>
    <version>5.6.15.Final</version>
</dependency>

<dependency>
    <groupId>com.vladmihalcea</groupId>
    <artifactId>hibernate-types-55</artifactId>
    <version>2.21.1</version>
</dependency>
```

```java
import com.vladmihalcea.hibernate.type.json.JsonType;
import org.hibernate.annotations.Type;
import org.hibernate.annotations.TypeDef;

@Entity
@TypeDef(name = "json", typeClass = JsonType.class)
public class Item {
    @Type(type = "json")
    @Column(columnDefinition = "json")
    private Map<String, String> spec;
}
```

- `@Type(type = "json")` 告诉 Hibernate 使用 `JsonType` 处理该字段。
- `@Column(columnDefinition = "json")` 明确告诉 liquibase-hibernate 生成 `JSON` 类型（某些数据库方言可能需要，比如 MySQL）。

## 更多参考

- [hibernate 5 hypersistence-utils库](https://www.baeldung-cn.com/hibernate-persist-json-object#5-使用-hypersistence-utils-库)
- [io.hypersistence/hypersistence-utils-hibernate-55](https://mvnrepository.com/artifact/io.hypersistence/hypersistence-utils-hibernate-55)
- [com.vladmihalcea/hibernate-types-55](https://mvnrepository.com/artifact/com.vladmihalcea/hibernate-types-55)
- [hibernate 6 @JdbcTypeCode JDBC类型代码注解](https://www.baeldung-cn.com/hibernate-persist-json-object#6-使用-jdbctypecode-注解（hibernate-6）)
- [hibernate 6 @Embeddable 嵌入实体类注解](https://www.baeldung-cn.com/hibernate-persist-json-object#7-将-json-映射到-embeddable-类（hibernate-6）)
- [hutool-bean-to-map](https://doc.hutool.cn/pages/BeanUtil/#bean转为map)
- [hutool-bean-to-bean](https://doc.hutool.cn/pages/BeanUtil/#bean转bean)
- [mp-type-handler-json](https://baomidou.com/guides/type-handler/#json-字段类型处理器)
