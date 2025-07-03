package com.SmartCanteen.Backend.Exceptions;

public class UsernameAlreadyExistsException extends RuntimeException {
    public UsernameAlreadyExistsException(String message) { super(message); }
}
