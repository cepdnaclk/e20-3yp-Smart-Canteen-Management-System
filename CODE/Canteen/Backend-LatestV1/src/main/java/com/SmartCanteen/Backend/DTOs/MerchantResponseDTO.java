package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class MerchantResponseDTO {
    private Long id;
    private String username;
    private String email;
    private String canteenName;
    // Maleesha's has CanteenName ;
}
