package com.SmartCanteen.Backend.DTOs;

public class ESP32VerifyRequest {
    private String email;
    private String fingerprintID;
    private String token;
    private long orderId;

    public ESP32VerifyRequest() {}

    public ESP32VerifyRequest(String email, String fingerprintID, String token, long orderId) {
        this.email = email;
        this.fingerprintID = fingerprintID;
        this.token = token;
        this.orderId = orderId;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFingerprintID() {
        return fingerprintID;
    }

    public void setFingerprintID(String fingerprintID) {
        this.fingerprintID = fingerprintID;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public long getOrderId() {
        return orderId;
    }

    public void setOrderId(long orderId) {
        this.orderId = orderId;
    }
}
