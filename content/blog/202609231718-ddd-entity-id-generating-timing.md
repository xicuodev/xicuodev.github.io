---
date: 2026-09-23T17:18:05+08:00
slug: ddd-entity-id-generating-timing
title: DDD中的实体ID应该在实体创建时立即生成
---
## 1. DDD中实体ID应该在创建实体时就生成

在领域驱动设计（DDD）中，实体的唯一身份标识（ID）是领域概念，不是数据库技术细节。DDD的许多环节都需要用到实体的唯一身份标识，比如发布领域事件、写日志、做幂等、放缓存、跨聚合引用、分布式操作、离线操作、批量操作等。因此，在DDD中，实体一诞生就要有唯一标识，而持久化只负责保存这个标识。无论是聚合根还是聚合成员，只要是创建实体时，就要为这个实体生成ID，而不应该等到持久化聚合时才生成。

## 2. 我在实体ID生成时机上犯的错误

我的XiCMusicJ项目就犯了这样的一个错误：我是等到聚合在仓储层持久化的时候才为聚合根生成雪花ID，并且更有甚者，我还把聚合成员的ID依赖于数据库本身的自增ID——也就是说，聚合成员必须要在持久化之后才能拥有自己的ID。这就导致聚合根和聚合成员从创建到持久化期间，都是没有ID的非法状态，或者说不健康状态。

其实，这种情况下，领域层隐式依赖了数据库，也就是基础设施层。这对于DDD来说就是犯了反向依赖的大忌，而我却没有发现。对于明显的情况，像基础设施层当中的某个具体的类依赖了领域层的类，我能看出来；但对于像这种领域层依赖了基础设施层中数据库的内部实现，我反而转不过来这个弯。不，更准确地说，应该是我默许了领域层对基础设施层的让步，我默许了领域层可以有ID为null的状态，并且不认为这种状态有什么问题。我没有看到实体ID对于领域层的重要作用。说到底，我就是对DDD的各种环节了解不清。

## 3. 怎么实现正确的实体ID生成机制？

对于聚合根，使用分布式雪花ID生成器，比如Hutool的 `IdUtil.getSeataSnowflakeNextId()`。但记得要在应用层中写实现细节（比如写一个 `Ids` 工具类），聚合内部不要依赖具体的ID生成工具。

- 对于聚合根ID的选型，雪花、UUID、ULID、号段都可以。雪花适合分布式趋势递增，但需要配置机器 ID，有时钟回拨问题。如果项目不大，UUID和ULID也完全可以。

对于聚合实体，在聚合根当中为每个聚合实体声明一个自增序号，持久化时把这些自增序号随聚合根存到数据库。移除聚合成员时，不会回退序号。这和数据库自增ID的原理类似，只不过把控制权从数据库转移到了领域模型。

- 移除聚合成员时，聚合根不会回退自增序号，这是为了防止复用导致的混乱。实体ID是实体的唯一身份标识，几乎所有系统都要依赖实体ID，你复用了不可能一个个去对账，成本太高。

```java
public class Order {
    private final OrderId id;
    private int itemSeq;
    private final List<OrderItem> items = new ArrayList<>();

    public void addItem(ProductId productId, int quantity) {
        OrderItemId itemId = new OrderItemId(this.id, ++this.itemSeq);
        OrderItem item = OrderItem.create(itemId, productId, quantity);
        items.add(item);
    }

    public static Order reconstitute(OrderId id, int itemSeq, List<OrderItem> items) {
	    Order order = new Order(id);
	    order.itemSeq = itemSeq;
	    order.items.addAll(items);
	    return order;
	}
}
```

```java
public class OrderItem {
    private final OrderItemId id;
    private final ProductId productId;
    private int quantity;

    private OrderItem(OrderItemId id, ProductId productId, int quantity) {
        this.id = id;
        this.productId = productId;
        this.quantity = quantity;
    }

    public static OrderItem create(OrderItemId id, ProductId productId, int quantity) {
        return new OrderItem(id, productId, quantity);
    }

    public static OrderItem reconstitute(OrderItemId id, ProductId productId, int quantity) {
        return new OrderItem(id, productId, quantity);
    }
}
```

```sql
-- 订单表
CREATE TABLE orders (
    id BIGINT PRIMARY KEY,           -- 聚合根id，全局唯一
    item_seq INT NOT NULL DEFAULT 0, -- 聚合根维护的局部序号
    ...
);

-- 订单明细表
CREATE TABLE order_items (
    order_id BIGINT NOT NULL,
    id INT NOT NULL,                 -- 订单明细id，依赖于局部序号
    product_id BIGINT NOT NULL,
    quantity INT NOT NULL,
    PRIMARY KEY (order_id, id),      -- 组合主键，保证唯一
    FOREIGN KEY (order_id) REFERENCES orders(id)
);
```
