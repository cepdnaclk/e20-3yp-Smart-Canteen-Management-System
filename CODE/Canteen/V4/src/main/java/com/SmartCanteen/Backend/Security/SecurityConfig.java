package com.SmartCanteen.Backend.Security;

import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@RequiredArgsConstructor
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
    private final CustomUserDetailsService userDetailsService;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())  // Disable CSRF for REST APIs
                .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint))
                .authorizeHttpRequests(auth -> auth
                        // Auth endpoints
                        .requestMatchers("/api/auth/login", "/api/auth/register/**").permitAll()

                        // Categories endpoints - allow all for testing; secure later as needed
                        .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/categories/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/categories/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/categories/**").permitAll()

                        // Menu items endpoints - allow all for testing; secure later as needed
                        .requestMatchers(HttpMethod.GET, "/api/menu/items/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/menu/items/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/menu/items/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/menu/items/**").permitAll()

                        //Customer CRUDs
                        .requestMatchers(HttpMethod.GET, "/api/customer/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/customer/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/customer/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/customer/**").permitAll()

                        //Merchant CRUDs
                        .requestMatchers(HttpMethod.GET, "/api/merchant/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/merchant/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/merchant/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/merchant/**").permitAll()

                        //Admin CRUDs
                        .requestMatchers(HttpMethod.GET, "/api/admin/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/admin/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/admin/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/admin/**").permitAll()

                        //Category CRUDs
                        .requestMatchers(HttpMethod.GET, "/api/food-categories/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/food-categories/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/food-categories/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/food-categories/**").permitAll()

                        //Menu CRUDs
                        .requestMatchers(HttpMethod.GET, "/api/menu-items/**").permitAll()
                        .requestMatchers(HttpMethod.POST, "/api/menu-items/**").permitAll()
                        .requestMatchers(HttpMethod.PUT, "/api/menu-items/**").permitAll()
                        .requestMatchers(HttpMethod.DELETE, "/api/menu-items/**").permitAll()



                        // TopUp CRUDs and related endpoints
                        .requestMatchers(HttpMethod.POST, "/api/topup/request").hasRole("CUSTOMER")
                        .requestMatchers(HttpMethod.GET, "/api/topup/pending").hasRole("MERCHANT")
                        .requestMatchers(HttpMethod.POST, "/api/topup/respond/**").hasRole("MERCHANT")

                        // Any other request requires authentication
                        .anyRequest().authenticated()
                )
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
        return config.getAuthenticationManager();
    }
}
