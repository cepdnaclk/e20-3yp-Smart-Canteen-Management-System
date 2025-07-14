package com.SmartCanteen.Backend.Entities;

public enum OrderStatus {
    PENDING,      // Order placed, awaiting merchant action
    ACCEPTED,     // Merchant accepted the order
    REJECTED,     // Merchant rejected the order
    PROCESSING,   // Order is being prepared
    COMPLETED,    // Order fulfilled
    FAILED, VERIFIED, CANCELLED     // Cancelled by customer or system
}
