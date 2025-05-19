package com.SmartCanteen.Backend.Security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Base64;
import java.util.Date;

@Component
public class JwtTokenProvider {

    @Value("${jwt.secret}")
    private String jwtSecretBase64;  // Base64-encoded secret from properties

    @Value("${jwt.expirationMs}")
    private int jwtExpirationMs;

    private SecretKey secretKey;

    @PostConstruct
    public void init() {
        // Decode the Base64-encoded secret key once during bean initialization
        byte[] decodedKey = Base64.getDecoder().decode(jwtSecretBase64);
        this.secretKey = Keys.hmacShaKeyFor(decodedKey);
    }

    // Generate JWT token with username and role claims
    public String generateToken(String username, String role) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationMs);

        return Jwts.builder()
                .setSubject(username)               // Set username as subject
                .claim("role", role)                // Add role as a custom claim
                .setIssuedAt(now)                   // Token issue time
                .setExpiration(expiryDate)          // Token expiration time
                .signWith(secretKey, SignatureAlgorithm.HS256)  // Sign with HS256 and secret key
                .compact();
    }

    // Validate the JWT token; throws exception if invalid
    public boolean validateToken(String token) {
        try {
            Jwts.parserBuilder()
                    .setSigningKey(secretKey)          // Use decoded secret key here
                    .build()
                    .parseClaimsJws(token);            // Parses and validates token
            return true;
        } catch (JwtException | IllegalArgumentException e) {
            // Token invalid or expired
            System.err.println("Invalid JWT token: " + e.getMessage());
            return false;
        }
    }

    // Extract username (subject) from token
    public String getUsernameFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token)
                .getBody();

        return claims.getSubject();
    }

    // Extract role claim from token
    public String getRoleFromToken(String token) {
        Claims claims = Jwts.parserBuilder()
                .setSigningKey(secretKey)
                .build()
                .parseClaimsJws(token)
                .getBody();

        return claims.get("role", String.class);
    }
}
