package com.SmartCanteen.Backend.Security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.util.Base64;
import java.util.Date;

@Component
public class JwtTokenProvider {

    private static final Logger logger = LoggerFactory.getLogger(JwtTokenProvider.class);

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

    // Validate the JWT token; returns true if valid, false otherwise
    public boolean validateToken(String token) {
        try {

                if (token == null || token.split("\\.").length != 3) {
                    throw new MalformedJwtException("Invalid token structure");
                }
            Jwts.parserBuilder()
                    .setSigningKey(secretKey)          // Use decoded secret key here
                    .build()
                    .parseClaimsJws(token);            // Parses and validates token
            return true;
        } catch (ExpiredJwtException e) {
            logger.warn("Expired JWT token: {}", e.getMessage());
        } catch (MalformedJwtException e) {
            logger.error("Malformed JWT token: {}", e.getMessage());
        } catch (UnsupportedJwtException e) {
            logger.error("Unsupported JWT token: {}", e.getMessage());
        } catch (IllegalArgumentException e) {
            logger.error("JWT claims string is empty: {}", e.getMessage());
        } catch (JwtException e) {
            logger.error("Invalid JWT token: {}", e.getMessage());
        }
        return false;
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
