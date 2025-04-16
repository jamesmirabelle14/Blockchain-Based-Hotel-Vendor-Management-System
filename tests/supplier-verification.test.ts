import { describe, it, expect, beforeEach, vi } from 'vitest';

// Mock the Clarity contract environment
const mockTxSender = 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM';
const mockAdmin = mockTxSender;
let mockBlockHeight = 100;

// Mock contract state
let suppliers = new Map();
let nextSupplierId = 1;

// Mock contract functions
const registerSupplier = (name, serviceType) => {
  const supplierId = nextSupplierId;
  
  suppliers.set(supplierId, {
    principal: mockTxSender,
    name,
    serviceType,
    status: 0,
    verificationDate: 0
  });
  
  nextSupplierId++;
  return { value: supplierId };
};

const verifySupplier = (supplierId, sender) => {
  if (sender !== mockAdmin) {
    return { error: 403 };
  }
  
  if (!suppliers.has(supplierId)) {
    return { error: 404 };
  }
  
  const supplier = suppliers.get(supplierId);
  suppliers.set(supplierId, {
    ...supplier,
    status: 1,
    verificationDate: mockBlockHeight
  });
  
  return { value: true };
};

const getSupplier = (supplierId) => {
  return suppliers.get(supplierId) || null;
};

const isVerified = (supplierId) => {
  const supplier = suppliers.get(supplierId);
  return supplier && supplier.status === 1;
};

// Tests
describe('Supplier Verification Contract', () => {
  beforeEach(() => {
    // Reset state before each test
    suppliers = new Map();
    nextSupplierId = 1;
    mockBlockHeight = 100;
  });
  
  it('should register a new supplier', () => {
    const result = registerSupplier('Acme Cleaning', 'Housekeeping');
    
    expect(result.value).toBe(1);
    expect(suppliers.size).toBe(1);
    expect(suppliers.get(1).name).toBe('Acme Cleaning');
    expect(suppliers.get(1).serviceType).toBe('Housekeeping');
    expect(suppliers.get(1).status).toBe(0); // Unverified
  });
  
  it('should verify a supplier', () => {
    registerSupplier('Acme Cleaning', 'Housekeeping');
    const result = verifySupplier(1, mockAdmin);
    
    expect(result.value).toBe(true);
    expect(suppliers.get(1).status).toBe(1); // Verified
    expect(suppliers.get(1).verificationDate).toBe(mockBlockHeight);
  });
  
  it('should not allow non-admin to verify suppliers', () => {
    registerSupplier('Acme Cleaning', 'Housekeeping');
    const result = verifySupplier(1, 'ST2PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM');
    
    expect(result.error).toBe(403);
    expect(suppliers.get(1).status).toBe(0); // Still unverified
  });
  
  it('should correctly identify verified suppliers', () => {
    registerSupplier('Acme Cleaning', 'Housekeeping');
    registerSupplier('Best Food', 'Catering');
    
    verifySupplier(1, mockAdmin);
    
    expect(isVerified(1)).toBe(true);
    expect(isVerified(2)).toBe(false);
  });
  
  it('should return null for non-existent suppliers', () => {
    expect(getSupplier(999)).toBe(null);
  });
});
