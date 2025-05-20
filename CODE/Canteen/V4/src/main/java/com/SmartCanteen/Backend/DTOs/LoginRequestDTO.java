package com.SmartCanteen.Backend.DTOs;

import lombok.Data;

@Data
public class LoginRequestDTO {
    private String username;
    private String password;
}
