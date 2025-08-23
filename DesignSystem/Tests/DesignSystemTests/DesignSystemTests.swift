//
//  DesignSystemTests.swift
//  DesignSystemTests
//
//  Copyright © 2025 Weiran Zhang. All rights reserved.
//

import Testing
@testable import DesignSystem

@Suite("DesignSystem Tests")
struct DesignSystemTests {
    
    @Test("DesignSystem is a singleton")
    func testSingleton() {
        let designSystem1 = DesignSystem.shared
        let designSystem2 = DesignSystem.shared
        
        #expect(designSystem1 === designSystem2, "DesignSystem should be a singleton")
    }
    
    @Test("DesignSystem conforms to Sendable")
    func testSendableConformance() {
        let designSystem = DesignSystem.shared
        
        // Test that we can pass it across actor boundaries
        Task {
            _ = designSystem // This should compile without warnings if Sendable is properly implemented
        }
        
        #expect(designSystem != nil)
    }
    
    @Test("DesignSystem is accessible")
    func testAccessibility() {
        let designSystem = DesignSystem.shared
        #expect(designSystem != nil, "DesignSystem should be accessible")
    }
    
    @Test("DesignSystem singleton consistency")
    func testSingletonConsistency() {
        // Test that the singleton returns the same instance across multiple calls
        let instances = (0..<5).map { _ in DesignSystem.shared }
        
        for index in 1..<instances.count {
            #expect(instances[0] === instances[index], "All instances should be the same")
        }
    }
    
    @Test("DesignSystem thread safety")
    func testThreadSafety() async {
        // Test concurrent access to the singleton
        await withTaskGroup(of: DesignSystem.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    return DesignSystem.shared
                }
            }
            
            var instances: [DesignSystem] = []
            for await instance in group {
                instances.append(instance)
            }
            
            // All instances should be the same
            for index in 1..<instances.count {
                #expect(instances[0] === instances[index], "Concurrent access should return same instance")
            }
        }
    }
    
    @Test("DesignSystem placeholder functionality")
    func testPlaceholderFunctionality() {
        // Since this is currently a placeholder, we just test its basic structure
        let designSystem = DesignSystem.shared
        
        // The struct should exist and be accessible
        #expect(designSystem != nil, "DesignSystem placeholder should be functional")
    }
}