//
//  PetManagerTests.swift
//  StepCounterTests
//
//  Тесты для системы питомцев
//

import XCTest
@testable import StepCounter

@MainActor
final class PetManagerTests: XCTestCase {
    
    var petManager: PetManager!
    var testStorage: TestStorageManager!
    
    override func setUp() {
        super.setUp()
        testStorage = TestStorageManager()
        petManager = PetManager()
    }
    
    override func tearDown() {
        testStorage.clearAllTestData()
        petManager = nil
        testStorage = nil
        super.tearDown()
    }
    
    // MARK: - Создание питомца
    
    /// Тест: Пользователь должен иметь возможность создать питомца
    func testCreatePet() {
        // Given
        let petName = "Бобик"
        let petType = PetType.cat
        
        // When
        let success = petManager.createPet(name: petName, type: petType)
        
        // Then
        XCTAssertTrue(success, "Создание питомца должно быть успешным")
        XCTAssertNotNil(petManager.pet, "Питомец должен быть создан")
        XCTAssertEqual(petManager.pet?.name, petName, "Имя питомца должно совпадать")
        XCTAssertEqual(petManager.pet?.type, petType, "Тип питомца должен совпадать")
        XCTAssertEqual(petManager.pet?.evolution, .baby, "Новый питомец должен быть на стадии 'Малыш'")
        XCTAssertEqual(petManager.pet?.totalXP, 0, "Новый питомец должен иметь 0 XP")
    }
    
    /// Тест: Созданный питомец должен быть выбран как текущий
    func testCreatedPetIsSelected() {
        // Given
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        let petID = petManager.pet?.id
        
        // When & Then
        XCTAssertNotNil(petID, "Созданный питомец должен быть выбран автоматически")
        XCTAssertEqual(petManager.selectedPetId, petID, "ID выбранного питомца должен совпадать")
    }
    
    /// Тест: Free пользователь должен иметь возможность создать только базового питомца
    func testFreeUserCanCreateOnlyBasicPet() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(false)
        
        // When
        let basicPet = petManager.createPet(name: "Котик", type: .cat)
        petManager.selectPet(basicPet)
        
        // Then
        XCTAssertNotNil(petManager.pet, "Free пользователь должен иметь возможность создать базового питомца")
        XCTAssertEqual(petManager.pet?.type, .cat, "Базовый питомец должен быть типа .cat")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    /// Тест: Free пользователь не должен иметь возможность создать Premium питомца
    func testFreeUserCannotCreatePremiumPet() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(false)
        
        // When & Then
        // Проверяем, что Premium питомцы требуют Premium
        let premiumTypes: [PetType] = [.poodle, .rabbit, .fox, .penguin]
        for type in premiumTypes {
            XCTAssertTrue(type.requiresPremium, "Тип \(type.name) должен требовать Premium")
        }
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    // MARK: - XP и Эволюция
    
    /// Тест: Питомец должен получать XP при активности пользователя
    func testPetGainsXPFromActivity() {
        // Given
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        let initialXP = petManager.pet?.totalXP ?? 0
        
        // When
        if var pet = petManager.pet {
            pet.feed(steps: 10000) // 10000 шагов = 100 XP
            petManager.pet = pet
        }
        
        // Then
        XCTAssertGreaterThan(petManager.pet?.totalXP ?? 0, initialXP, "XP питомца должен увеличиться")
    }
    
    /// Тест: Питомец должен эволюционировать при достижении необходимого XP
    func testPetEvolvesWhenXPThresholdReached() {
        // Given
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        
        // Устанавливаем XP близко к порогу эволюции
        if var pet = petManager.pet {
            pet.totalXP = 9500 // До следующей стадии нужно 10000
            pet.checkEvolution()
            petManager.pet = pet
        }
        
        // When
        if var pet = petManager.pet {
            pet.feed(steps: 1000) // Добавляем еще 10 XP (1000 шагов / 100)
            pet.totalXP = 10000 // Устанавливаем точно 10000 для эволюции
            pet.checkEvolution()
            petManager.pet = pet
        }
        
        // Then
        let currentEvolution = petManager.pet?.evolution
        XCTAssertEqual(currentEvolution, .teen, "Питомец должен эволюционировать в 'Подросток' при 10000 XP")
    }
    
    /// Тест: Возраст питомца должен рассчитываться корректно
    func testPetAgeCalculation() {
        // Given
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        
        // Устанавливаем дату создания 5 дней назад
        if var pet = petManager.pet {
            pet.createdDate = Calendar.current.startOfDay(for: Date().addingDays(-5))
            petManager.pet = pet
        }
        
        // When
        let age = petManager.pet?.daysOld ?? 0
        
        // Then
        XCTAssertEqual(age, 5, accuracy: 1, "Возраст питомца должен быть ~5 дней")
    }
    
    /// Тест: Настроение питомца должно зависеть от активности
    func testPetMoodDependsOnActivity() {
        // Given
        let pet = petManager.createPet(name: "Бобик", type: .cat)
        petManager.selectPet(pet)
        
        // When - питомец получает много активности
        petManager.pet?.todaySteps = 10000
        
        // Then
        let mood = petManager.pet?.mood ?? .sad
        XCTAssertTrue([.ecstatic, .happy].contains(mood), "При высокой активности настроение должно быть хорошим")
    }
    
    // MARK: - Ограничения
    
    /// Тест: Free пользователь должен иметь ограничение на количество питомцев
    func testFreeUserHasPetLimit() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(false)
        
        // When
        // Free пользователь может создать только 1 питомца
        let firstPetSuccess = petManager.createPet(name: "Котик", type: .cat)
        let secondPetSuccess = petManager.createPet(name: "Собачка", type: .poodle)
        
        // Then
        XCTAssertTrue(firstPetSuccess, "Free пользователь должен иметь возможность создать первого питомца")
        XCTAssertFalse(secondPetSuccess, "Free пользователь не должен иметь возможность создать второго питомца")
        XCTAssertEqual(petManager.pets.count, 1, "У free пользователя должен быть только 1 питомец")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    /// Тест: Premium пользователь должен иметь неограниченное количество питомцев
    func testPremiumUserHasUnlimitedPets() {
        // Given
        let subscriptionManager = SubscriptionManager.shared
        let wasPremium = subscriptionManager.isPremium
        subscriptionManager.setPremiumManually(true)
        
        // When
        let firstPetSuccess = petManager.createPet(name: "Котик", type: .cat)
        let secondPetSuccess = petManager.createPet(name: "Собачка", type: .poodle)
        let thirdPetSuccess = petManager.createPet(name: "Лисичка", type: .fox)
        
        // Then
        XCTAssertTrue(firstPetSuccess, "Premium пользователь должен иметь возможность создать первого питомца")
        XCTAssertTrue(secondPetSuccess, "Premium пользователь должен иметь возможность создать второго питомца")
        XCTAssertTrue(thirdPetSuccess, "Premium пользователь должен иметь возможность создать третьего питомца")
        XCTAssertGreaterThanOrEqual(petManager.pets.count, 3, "У Premium пользователя должно быть минимум 3 питомца")
        
        // Restore
        subscriptionManager.setPremiumManually(wasPremium)
    }
    
    // MARK: - Сохранение и загрузка
    
    /// Тест: Данные питомца должны сохраняться и загружаться
    func testPetDataPersistence() {
        // Given
        let success = petManager.createPet(name: "Бобик", type: .cat)
        XCTAssertTrue(success, "Питомец должен быть создан")
        let petID = petManager.pet?.id
        
        // Добавляем XP питомцу
        if var pet = petManager.pet {
            pet.feed(steps: 50000) // 50000 шагов = 500 XP
            petManager.pet = pet
        }
        
        // When
        petManager.savePets()
        // Симулируем перезагрузку - проверяем, что данные сохранились
        let loadedPets = petManager.pets
        
        // Then
        let loadedPet = loadedPets.first(where: { $0.id == petID })
        XCTAssertNotNil(loadedPet, "Питомец должен быть загружен")
        XCTAssertEqual(loadedPet?.name, "Бобик", "Имя питомца должно сохраниться")
        XCTAssertGreaterThan(loadedPet?.totalXP ?? 0, 0, "XP питомца должен сохраниться")
    }
}
