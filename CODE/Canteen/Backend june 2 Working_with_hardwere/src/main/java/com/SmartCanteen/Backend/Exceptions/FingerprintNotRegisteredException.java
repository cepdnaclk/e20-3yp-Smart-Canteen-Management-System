package com.SmartCanteen.Backend.Exceptions;

public class FingerprintNotRegisteredException extends RuntimeException {
    public FingerprintNotRegisteredException(String message) {
        super(message);
    }
}