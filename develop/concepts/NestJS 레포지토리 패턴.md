---
created: 2026-03-08
updated: 2026-03-08
tags: [concept, backend, design]
status: done
---

# NestJS 레포지토리 패턴

> NestJS에서 데이터 접근 계층을 구성하는 두 가지 방식인 `@InjectRepository()` 직접 사용과 커스텀 `@Injectable()` 레포지토리 패턴을 비교하는 문서입니다.

---

## 1. 정의

NestJS에서 TypeORM을 사용할 때, 데이터 접근 계층을 구성하는 방식은 크게 두 가지입니다.

- **`@InjectRepository()` 직접 사용**: TypeORM이 자동 생성한 기본 `Repository<Entity>`를 Service에 바로 주입하는 방식입니다.
- **커스텀 `@Injectable()` 레포지토리**: 기본 레포지토리를 래핑하는 별도의 클래스를 만들어 도메인 특화 쿼리를 캡슐화하는 방식입니다.

두 방식은 대립 관계가 아니라 포함 관계입니다. 커스텀 레포지토리 내부에서 `@InjectRepository()`를 사용합니다.

---

## 2. 등장 배경 및 필요성

- **TypeORM `@EntityRepository` 폐기**: TypeORM 0.3.0에서 `@EntityRepository` 데코레이터가 폐기되면서, NestJS의 DI 시스템과 자연스럽게 통합되는 `@Injectable()` 기반 커스텀 레포지토리 패턴이 권장 방식이 되었습니다.
- **Service 계층의 비대화**: 복잡한 쿼리 로직이 Service에 직접 작성되면, 비즈니스 로직과 데이터 접근 로직이 혼재되어 유지보수가 어려워집니다.
- **테스트 용이성**: `@InjectRepository()`를 직접 사용하면 테스트 시 TypeORM 모듈 전체를 모킹해야 합니다. 커스텀 레포지토리로 분리하면 단위 테스트가 간결해집니다.

---

## 3. 핵심 개념

### 3.1 `@InjectRepository()` 직접 사용

`TypeOrmModule.forFeature()`로 엔티티를 등록하면, TypeORM이 해당 엔티티의 기본 `Repository`를 자동 생성합니다. Service에서 `@InjectRepository()` 데코레이터로 이를 주입받아 사용합니다.

```typescript
// user.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UserService],
})
export class UserModule {}

// user.service.ts
@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private userRepo: Repository<User>,
  ) {}

  findAll() {
    return this.userRepo.find();
  }

  findByEmail(email: string) {
    return this.userRepo.findOne({ where: { email } });
  }
}
```

**특징**: 설정이 간단하고 기본 CRUD(`find`, `save`, `delete`)만으로 충분한 경우에 적합합니다. 쿼리 로직이 Service에 직접 위치합니다.

### 3.2 커스텀 `@Injectable()` 레포지토리

기본 레포지토리를 래핑하는 별도의 클래스를 `@Injectable()`로 선언하고, 도메인 특화 쿼리 메서드를 정의합니다.

```typescript
// user.repository.ts
@Injectable()
export class UserRepository {
  constructor(
    @InjectRepository(User)
    private repo: Repository<User>,
  ) {}

  findActiveByEmail(email: string) {
    return this.repo.findOne({
      where: { email, isActive: true },
    });
  }

  findWithRecentOrders(since: Date) {
    return this.repo.createQueryBuilder('user')
      .innerJoinAndSelect('user.orders', 'order')
      .where('user.isActive = :active', { active: true })
      .andWhere('order.createdAt > :since', { since })
      .getMany();
  }
}

// user.module.ts
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UserRepository, UserService],
})
export class UserModule {}

// user.service.ts
@Injectable()
export class UserService {
  constructor(private userRepo: UserRepository) {}

  async getActiveUser(email: string) {
    const user = await this.userRepo.findActiveByEmail(email);
    if (!user) throw new NotFoundException();
    return user;
  }
}
```

**특징**: Service는 비즈니스 로직에만 집중하고, 쿼리 로직은 Repository에 캡슐화됩니다. 복잡한 QueryBuilder 호출이 Service에 노출되지 않습니다.

### 3.3 계층 구조 비교

```
[직접 사용]                    [커스텀 레포지토리]
Controller                    Controller
    ↓                             ↓
Service (비즈니스 + 쿼리)      Service (비즈니스 로직만)
    ↓                             ↓
Repository<Entity>            UserRepository (쿼리 캡슐화)
                                  ↓
                              Repository<Entity>
```

---

## 4. 장점 및 이점

### 4.1 커스텀 레포지토리의 이점

- **관심사 분리**: 비즈니스 로직(Service)과 데이터 접근 로직(Repository)이 명확히 분리됩니다.
- **재사용성**: 동일한 쿼리를 여러 Service에서 호출할 때 중복 코드가 제거됩니다.
- **테스트 용이성**: Repository를 모킹하면 Service 테스트에서 데이터베이스 의존을 완전히 제거할 수 있습니다.
- **ORM 교체 대응**: 데이터 접근이 Repository에 격리되어 있으므로, TypeORM에서 다른 ORM으로 전환할 때 Service 코드를 수정할 필요가 없습니다.

### 4.2 `@InjectRepository()` 직접 사용의 이점

- **설정 최소화**: 별도 클래스 없이 바로 사용할 수 있어 초기 개발 속도가 빠릅니다.
- **보일러플레이트 감소**: 단순 CRUD만 필요한 경우 래퍼 클래스가 불필요한 추상화 계층이 됩니다.

---

## 5. 한계점 및 고려사항

- **과도한 추상화 주의**: 단순 `find`, `save`만 사용하는 엔티티에 커스텀 레포지토리를 만들면 불필요한 코드가 늘어납니다.
- **TypeORM 종속**: 두 방식 모두 내부적으로 TypeORM의 `Repository<Entity>`에 의존합니다. 완전한 ORM 독립을 원한다면 인터페이스 기반 추상 레포지토리 패턴을 추가로 도입해야 합니다.
- **`@EntityRepository` 폐기**: TypeORM 0.3.0 이전의 `extends Repository<Entity>` 방식은 더 이상 사용할 수 없습니다. 반드시 `@Injectable()` + `@InjectRepository()` 조합을 사용해야 합니다.

---

## 6. 실무 적용 가이드

### 6.1 선택 기준

| 상황 | 권장 방식 |
|------|----------|
| 단순 CRUD, 프로토타입, 소규모 프로젝트 | `@InjectRepository()` 직접 사용 |
| 복잡한 쿼리(QueryBuilder, 서브쿼리 등) | 커스텀 레포지토리 |
| 동일 쿼리를 여러 Service에서 사용 | 커스텀 레포지토리 |
| 단위 테스트 커버리지가 중요한 경우 | 커스텀 레포지토리 |
| 프로덕션 수준의 대규모 프로젝트 | 커스텀 레포지토리 |

### 6.2 테스트 비교

```typescript
// @InjectRepository() 직접 사용 시 테스트 — TypeORM 모듈 모킹 필요
const module = await Test.createTestingModule({
  imports: [TypeOrmModule.forFeature([User])],
  providers: [UserService],
}).compile();

// 커스텀 레포지토리 사용 시 테스트 — 간단한 모킹으로 충분
const module = await Test.createTestingModule({
  providers: [
    UserService,
    { provide: UserRepository, useValue: mockUserRepo },
  ],
}).compile();
```

---

## 관련 문서

- [[디자인 패턴 비교]] - Provider, Strategy, Factory 패턴 비교
- [[SOLID]] - 단일 책임 원칙(SRP)과 의존성 역전 원칙(DIP) 관점에서의 계층 분리

---

## 참고 자료

- [NestJS 공식 문서 - Database](https://docs.nestjs.com/techniques/database) - TypeORM 통합 가이드
- [Implementing the Repository Pattern in NestJS](https://medium.com/@mitchella0100/implementing-the-repository-pattern-in-nestjs-and-why-we-should-e32861df5457) - 레포지토리 패턴 도입 사례
- [Repository Pattern in NestJS: Do It Right or Go Home](https://dev.to/adamthedeveloper/repository-pattern-in-nestjs-do-it-right-or-go-home-268f) - 커스텀 레포지토리 구현 가이드
- [Making Your NestJS Services Testable](https://medium.com/@aya986/making-your-nestjs-services-testable-the-right-way-to-inject-typeorm-repositories-bd31410acbcf) - 테스트 용이성 관점의 비교
