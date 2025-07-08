package com.SmartCanteen.Backend.DTOs;

public class FingerprintResponseDto {
    private String email;
    private String fingerprintId;

    public FingerprintResponseDto() {}

    public FingerprintResponseDto(String email, String fingerprintId) {
        this.email = email;
        this.fingerprintId = fingerprintId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFingerprintId() {
        return fingerprintId;
    }

    public void setFingerprintId(String fingerprintId) {
        this.fingerprintId = fingerprintId;
    }
}

