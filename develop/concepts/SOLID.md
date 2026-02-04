---
created: 2026-02-05
updated: 2026-02-05
tags: [concept, oop, design]
status: done
---

# SOLID

> 객체지향 설계의 5가지 핵심 원칙으로, 유지보수성과 확장성이 높은 소프트웨어를 만들기 위한 가이드라인입니다.

---

## 1. 개요

SOLID는 로버트 마틴(Robert C. Martin)이 정리한 객체지향 설계의 5가지 원칙의 앞글자를 딴 약어입니다.

| 원칙 | 영문 | 핵심 |
|------|------|------|
| **S** | Single Responsibility | 하나의 책임만 |
| **O** | Open-Closed | 확장에 열림, 수정에 닫힘 |
| **L** | Liskov Substitution | 하위 타입 치환 가능 |
| **I** | Interface Segregation | 인터페이스 분리 |
| **D** | Dependency Inversion | 추상화에 의존 |

---

## 2. 각 원칙 상세

### 2.1 단일 책임 원칙 (SRP)

**Single Responsibility Principle**

> 클래스는 하나의 책임만 가져야 하며, 변경의 이유는 오직 하나여야 합니다.

```java
// 위반: 여러 책임이 섞여 있음
class UserService {
    void createUser() { ... }
    void sendEmail() { ... }      // 이메일 책임
    void generateReport() { ... } // 리포트 책임
}

// 준수: 책임 분리
class UserService {
    void createUser() { ... }
}
class EmailService {
    void sendEmail() { ... }
}
class ReportService {
    void generateReport() { ... }
}
```

**판단 기준:** "이 클래스가 변경되어야 하는 이유가 몇 가지인가?"

---

### 2.2 개방-폐쇄 원칙 (OCP)

**Open-Closed Principle**

> 확장에는 열려 있고, 수정에는 닫혀 있어야 합니다.

기존 코드를 수정하지 않고 새로운 기능을 추가할 수 있어야 합니다.

```java
// 위반: 새 결제 수단 추가 시 기존 코드 수정 필요
class PaymentProcessor {
    void process(String type) {
        if (type.equals("card")) { ... }
        else if (type.equals("bank")) { ... }
        // 새 결제 수단 추가할 때마다 여기 수정
    }
}

// 준수: 인터페이스로 확장
interface PaymentMethod {
    void pay();
}
class CardPayment implements PaymentMethod { ... }
class BankPayment implements PaymentMethod { ... }
class CryptoPayment implements PaymentMethod { ... } // 새로 추가해도 기존 코드 수정 없음
```

---

### 2.3 리스코프 치환 원칙 (LSP)

**Liskov Substitution Principle**

> 하위 타입은 상위 타입을 대체할 수 있어야 합니다.

부모 클래스를 사용하는 곳에 자식 클래스를 넣어도 동작이 깨지면 안 됩니다.

```java
// 위반: 정사각형은 직사각형의 하위 타입이 될 수 없음
class Rectangle {
    void setWidth(int w) { this.width = w; }
    void setHeight(int h) { this.height = h; }
}
class Square extends Rectangle {
    void setWidth(int w) {
        this.width = w;
        this.height = w; // 정사각형이라 높이도 변경 → 예상과 다른 동작
    }
}
```

**핵심:** 상속보다 구성(Composition)을 고려하세요.

---

### 2.4 인터페이스 분리 원칙 (ISP)

**Interface Segregation Principle**

> 클라이언트는 자신이 사용하지 않는 메서드에 의존하지 않아야 합니다.

하나의 범용 인터페이스보다 여러 개의 구체적인 인터페이스가 낫습니다.

```java
// 위반: 모든 기능이 하나의 인터페이스에
interface Worker {
    void work();
    void eat();
    void sleep();
}
class Robot implements Worker {
    void work() { ... }
    void eat() { /* 로봇은 안 먹음 */ }  // 불필요한 구현 강제
    void sleep() { /* 로봇은 안 잠 */ }
}

// 준수: 인터페이스 분리
interface Workable { void work(); }
interface Eatable { void eat(); }
interface Sleepable { void sleep(); }

class Robot implements Workable { ... }
class Human implements Workable, Eatable, Sleepable { ... }
```

---

### 2.5 의존성 역전 원칙 (DIP)

**Dependency Inversion Principle**

> 고수준 모듈은 저수준 모듈에 의존하지 않고, 둘 다 추상화에 의존해야 합니다.

```java
// 위반: 고수준이 저수준 구현체에 직접 의존
class OrderService {
    private MySQLDatabase db = new MySQLDatabase(); // 구체 클래스에 의존
}

// 준수: 추상화에 의존
interface Database { void save(); }
class MySQLDatabase implements Database { ... }
class PostgresDatabase implements Database { ... }

class OrderService {
    private Database db; // 인터페이스에 의존
    OrderService(Database db) { this.db = db; }
}
```

**결과:** 테스트 용이, DB 교체 용이

---

## 3. 원칙 간 관계

```
SRP (단일 책임) ← 클래스 설계의 기본
    ↓
OCP (개방-폐쇄) ← 확장 가능한 구조
    ↓
LSP (리스코프 치환) ← 올바른 상속 관계
    ↓
ISP (인터페이스 분리) ← 적절한 인터페이스 설계
    ↓
DIP (의존성 역전) ← 유연한 의존 관계
```

모든 원칙은 결국 **변경에 유연하게 대응**하기 위한 것입니다.

---

## 4. 실무 적용 시 주의점

- **과도한 적용 금지:** 모든 코드에 SOLID를 강제하면 오히려 복잡해집니다
- **상황에 맞게:** 변경 가능성이 낮은 곳에는 단순한 구현이 나을 수 있습니다
- **점진적 적용:** 리팩토링 시점에 필요한 원칙부터 적용합니다

---

## 관련 문서

- [[일반화와 추상화]] - 객체지향 설계의 기본 개념

---

## 참고 자료

- [Clean Code](https://www.amazon.com/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882) - Robert C. Martin
