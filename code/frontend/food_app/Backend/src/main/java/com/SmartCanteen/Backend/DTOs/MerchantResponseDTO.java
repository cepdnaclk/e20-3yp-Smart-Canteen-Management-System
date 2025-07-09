package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class MerchantResponseDTO {
    private Long id;
    private String username;
    private String email;
    private String CanteenName;
  //  private String fullName;
}
