//////package com.SmartCanteen.Backend.Security;
//////
//////import lombok.RequiredArgsConstructor;
//////import org.springframework.context.annotation.Bean;
//////import org.springframework.context.annotation.Configuration;
//////import org.springframework.http.HttpMethod;
//////import org.springframework.security.authentication.AuthenticationManager;
//////import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
//////import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
//////import org.springframework.security.config.annotation.web.builders.HttpSecurity;
//////import org.springframework.security.config.http.SessionCreationPolicy;
//////import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
//////import org.springframework.security.crypto.password.PasswordEncoder;
//////import org.springframework.security.web.SecurityFilterChain;
//////import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
//////import org.springframework.web.cors.CorsConfiguration;
//////import org.springframework.web.cors.CorsConfigurationSource;
//////import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
//////
//////
//////import java.util.List;
//////
//////@Configuration
//////@RequiredArgsConstructor
//////@EnableMethodSecurity
//////public class SecurityConfig {
//////
//////    private final JwtAuthenticationFilter jwtAuthenticationFilter;
//////    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
//////    private final CustomUserDetailsService userDetailsService;
//////
//////    @Bean
//////    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
//////        http
//////                .csrf(csrf -> csrf.disable())  // Disable CSRF for REST APIs
//////                .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint))
//////                .authorizeHttpRequests(auth -> auth
//////                        // Auth endpoints
//////                        .requestMatchers("/api/auth/login", "/api/auth/register/**", "/api/auth/verify-email", "/api/auth/resend-code").permitAll()
//////                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
//////
//////                        // Categories endpoints - allow all for testing; secure later as needed
//////                        .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/categories/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/categories/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/categories/**").permitAll()
//////
//////                        // Menu items endpoints - allow all for testing; secure later as needed
//////                        .requestMatchers(HttpMethod.GET, "/api/menu/items/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/menu/items/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/menu/items/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/menu/items/**").permitAll()
//////
//////                        // Customer CRUDs
//////                        .requestMatchers(HttpMethod.GET, "/api/customer/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/customer/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/customer/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/customer/**").permitAll()
//////
//////                        // Merchant CRUDs
//////                        .requestMatchers(HttpMethod.GET, "/api/merchant/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/merchant/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/merchant/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/merchant/**").permitAll()
//////
//////                        // Admin CRUDs
//////                        .requestMatchers(HttpMethod.GET, "/api/admin/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/admin/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/admin/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/admin/**").permitAll()
//////
//////                        // Category CRUDs
//////                        .requestMatchers(HttpMethod.GET, "/api/food-categories/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/food-categories/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/food-categories/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/food-categories/**").permitAll()
//////
//////                        // Menu CRUDs
//////                        .requestMatchers(HttpMethod.GET, "/api/menu-items/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/menu-items/**").permitAll()
//////                        .requestMatchers(HttpMethod.PUT, "/api/menu-items/**").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/menu-items/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/uploads/**").permitAll()
//////
//////                        // Today's menu endpoints (MUST be before .anyRequest())
//////                        .requestMatchers(HttpMethod.POST, "/api/menu/today").permitAll()
//////                        .requestMatchers(HttpMethod.GET, "/api/menu/today").permitAll()
//////
//////                        // TopUp CRUDs and related endpoints
//////                        .requestMatchers(HttpMethod.GET, "/api/topup/pending").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/topup/respond/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/topup/request").permitAll()
//////                        .requestMatchers(HttpMethod.GET, "/api/topup/balance").permitAll()
//////
//////                        .requestMatchers(HttpMethod.GET, "/api/topup/pending").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/topup/respond/**").permitAll()
//////                        .requestMatchers(HttpMethod.POST, "/api/topup/request").permitAll()
//////                        .requestMatchers(HttpMethod.GET, "/api/topup/balance").permitAll()
//////                        .requestMatchers(HttpMethod.GET, "/api/topup/my-requests").permitAll()
//////                        .requestMatchers(HttpMethod.DELETE, "/api/topup/request/**").permitAll()
//////
//////                        // Any other request requires authentication (keep this LAST)
//////                        .anyRequest().authenticated()
//////                )
//////                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
//////                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
//////
//////        return http.build();
//////    }
//////    @Bean
//////    public CorsConfigurationSource corsConfigurationSource() {
//////        CorsConfiguration config = new CorsConfiguration();
//////        config.setAllowedOrigins(List.of("http://localhost:8080", "http://localhost:YOUR_FLUTTER_PORT"));
//////        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
//////        config.setAllowedHeaders(List.of("*"));
//////        config.setExposedHeaders(List.of("Authorization"));
//////        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
//////        source.registerCorsConfiguration("/**", config);
//////        return source;
//////    }
//////
//////    @Bean
//////    public PasswordEncoder passwordEncoder() {
//////        return new BCryptPasswordEncoder();
//////    }
//////
//////    @Bean
//////    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
//////        return config.getAuthenticationManager();
//////    }
//////}
////
////package com.SmartCanteen.Backend.Security;
////
////import lombok.RequiredArgsConstructor;
////import org.springframework.context.annotation.Bean;
////import org.springframework.context.annotation.Configuration;
////import org.springframework.http.HttpMethod;
////import org.springframework.security.authentication.AuthenticationManager;
////import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
////import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
////import org.springframework.security.config.annotation.web.builders.HttpSecurity;
////import org.springframework.security.config.http.SessionCreationPolicy;
////import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
////import org.springframework.security.crypto.password.PasswordEncoder;
////import org.springframework.security.web.SecurityFilterChain;
////import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
////import org.springframework.web.cors.CorsConfiguration;
////import org.springframework.web.cors.CorsConfigurationSource;
////import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
////
////import java.util.List;
////
////@Configuration
////@RequiredArgsConstructor
////@EnableMethodSecurity
////public class SecurityConfig {
////
////    private final JwtAuthenticationFilter jwtAuthenticationFilter;
////    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
////    private final CustomUserDetailsService userDetailsService;
////
////    @Bean
////    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
////        http
////                .csrf(csrf -> csrf.disable())
////                .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint))
////                .authorizeHttpRequests(auth -> auth
////                        // Auth endpoints
////                        .requestMatchers("/api/auth/login", "/api/auth/register/**", "/api/auth/verify-email", "/api/auth/resend-code").permitAll()
////                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
////
////                        // Categories endpoints
////                        .requestMatchers(HttpMethod.GET, "/api/categories/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/categories/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/categories/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/categories/**").permitAll()
////
////                        // Menu items endpoints
////                        .requestMatchers(HttpMethod.GET, "/api/menu/items/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/menu/items/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/menu/items/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/menu/items/**").permitAll()
////
////                        // Customer CRUDs
////                        .requestMatchers(HttpMethod.GET, "/api/customer/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/customer/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/customer/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/customer/**").permitAll()
////
////                        // Merchant CRUDs
////                        .requestMatchers(HttpMethod.GET, "/api/merchant/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/merchant/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/merchant/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/merchant/**").permitAll()
////
////                        // Admin CRUDs
////                        .requestMatchers(HttpMethod.GET, "/api/admin/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/admin/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/admin/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/admin/**").permitAll()
////
////                        // Food category CRUDs
////                        .requestMatchers(HttpMethod.GET, "/api/food-categories/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/food-categories/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/food-categories/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/food-categories/**").permitAll()
////
////                        // Menu CRUDs
////                        .requestMatchers(HttpMethod.GET, "/api/menu-items/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/menu-items/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/menu-items/**").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/menu-items/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/uploads/**").permitAll()
////
////                        // Today's menu
////                        .requestMatchers(HttpMethod.POST, "/api/menu/today").permitAll()
////                        .requestMatchers(HttpMethod.GET, "/api/menu/today").permitAll()
////
////                        // TopUp endpoints
////                        .requestMatchers(HttpMethod.GET, "/api/topup/pending").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/topup/respond/**").permitAll()
////                        .requestMatchers(HttpMethod.POST, "/api/topup/request").permitAll()
////                        .requestMatchers(HttpMethod.GET, "/api/topup/balance").permitAll()
////                        .requestMatchers(HttpMethod.GET, "/api/topup/my-requests").permitAll()
////                        .requestMatchers(HttpMethod.DELETE, "/api/topup/request/**").permitAll()
////
////                        // Order endpoints (NEWLY ADDED)
////                        .requestMatchers(HttpMethod.POST, "/api/orders/place").permitAll()
////                        .requestMatchers(HttpMethod.GET, "/api/orders/customer/**").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/orders/*/status").permitAll()
////                        .requestMatchers(HttpMethod.GET, "/api/orders/merchant/pending").permitAll()
////                        .requestMatchers(HttpMethod.PUT, "/api/orders/cancel/**").permitAll()
////
////                        // Any other request
////                        .anyRequest().authenticated()
////                )
////                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
////                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
////
////        return http.build();
////    }
////
////    @Bean
////    public CorsConfigurationSource corsConfigurationSource() {
////        CorsConfiguration config = new CorsConfiguration();
////        config.setAllowedOrigins(List.of("http://localhost:8080", "http://localhost:YOUR_FLUTTER_PORT"));
////        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
////        config.setAllowedHeaders(List.of("*"));
////        config.setExposedHeaders(List.of("Authorization"));
////        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
////        source.registerCorsConfiguration("/**", config);
////        return source;
////    }
////
////    @Bean
////    public PasswordEncoder passwordEncoder() {
////        return new BCryptPasswordEncoder();
////    }
////
////    @Bean
////    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
////        return config.getAuthenticationManager();
////    }
////}
//
//
//package com.SmartCanteen.Backend.Security;
//
//import lombok.RequiredArgsConstructor;
//import org.springframework.context.annotation.Bean;
//import org.springframework.context.annotation.Configuration;
//import org.springframework.http.HttpMethod;
//import org.springframework.security.authentication.AuthenticationManager;
//import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
//import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
//import org.springframework.security.config.annotation.web.builders.HttpSecurity;
//import org.springframework.security.config.http.SessionCreationPolicy;
//import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
//import org.springframework.security.crypto.password.PasswordEncoder;
//import org.springframework.security.web.SecurityFilterChain;
//import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
//import org.springframework.web.cors.CorsConfiguration;
//import org.springframework.web.cors.CorsConfigurationSource;
//import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
//
//import java.util.List;
//
//@Configuration
//@RequiredArgsConstructor
//@EnableMethodSecurity
//public class SecurityConfig {
//
//    private final JwtAuthenticationFilter jwtAuthenticationFilter;
//    private final JwtAuthenticationEntryPoint jwtAuthenticationEntryPoint;
//    private final CustomUserDetailsService userDetailsService;
//
//    @Bean
//    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
//        http
//                .csrf(csrf -> csrf.disable())
//                .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint))
//                .authorizeHttpRequests(auth -> auth
//                        // Auth endpoints
//                        .requestMatchers("/api/auth/login","/api/auth/forgot-password","/api/auth/reset-password", "/api/auth/register/**", "/api/auth/verify-email", "/api/auth/resend-code").permitAll()
//                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
//
//                        // Category and menu management (open during development/testing)
//                        .requestMatchers("/api/categories/**", "/api/food-categories/**").permitAll()
//                        .requestMatchers("/api/menu/items/**", "/api/menu-items/**", "/api/uploads/**").permitAll()
//
//                        // Customer, Merchant, Admin CRUD
//                        .requestMatchers("/api/customer/**", "/api/merchant/**", "/api/admin/**").permitAll()
//                        .requestMatchers("/api/admin/**").hasRole("ADMIN")
//
//                        // Today's Menu
//                        .requestMatchers("/api/menu/today").permitAll()
//
//                        // Top-Up related endpoints
//                        .requestMatchers("/api/topup/**").permitAll()
//
//                        // Orders (NEW)
//                        .requestMatchers("/api/orders/place").permitAll()
//                        .requestMatchers("/api/orders/customer/**").permitAll()
//                        .requestMatchers("/api/orders/merchant/pending").permitAll()
//                        .requestMatchers("/api/orders/merchant/*/accept").permitAll()
//                        .requestMatchers("/api/orders/merchant/*/complete").permitAll()
//                        .requestMatchers("/api/orders/merchant/*/completeDirectly").permitAll()
//                        .requestMatchers("/api/orders/*/status").permitAll()
//                        .requestMatchers("/api/orders/cancel/**").permitAll()
//                        .requestMatchers("/api/orders/**").permitAll()
//                        .requestMatchers("/api/orders/merchant/accepted").permitAll()
//                        .requestMatchers(HttpMethod.POST, "/api/messages/send").hasAnyRole("CUSTOMER", "MERCHANT")
//                        .requestMatchers(HttpMethod.GET, "/api/messages/conversation/**").hasAnyRole("CUSTOMER", "MERCHANT")
//                        .requestMatchers(HttpMethod.GET, "/api/uploads/**").permitAll() // Allow public access to uploaded files
//
//
//                        // Any other request requires authentication
//                        .anyRequest().authenticated()
//                )
//                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
//                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
//
//        return http.build();
//    }
//
//    @Bean
//    public CorsConfigurationSource corsConfigurationSource() {
//        CorsConfiguration config = new CorsConfiguration();
//        config.setAllowedOrigins(List.of("http://localhost:8080", "http://localhost:5000")); // replace 5000 with actual Flutter port if known
//        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
//        config.setAllowedHeaders(List.of("*"));
//        config.setExposedHeaders(List.of("Authorization"));
//        config.setAllowCredentials(true);
//
//        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
//        source.registerCorsConfiguration("/**", config);
//        return source;
//    }
//
//    @Bean
//    public PasswordEncoder passwordEncoder() {
//        return new BCryptPasswordEncoder();
//    }
//
//    @Bean
//    public AuthenticationManager authenticationManager(AuthenticationConfiguration config) throws Exception {
//        return config.getAuthenticationManager();
//    }
//}


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
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

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
                .csrf(csrf -> csrf.disable())
                .exceptionHandling(exception -> exception.authenticationEntryPoint(jwtAuthenticationEntryPoint))
                .authorizeHttpRequests(auth -> auth
                        // Auth endpoints - open
                        .requestMatchers("/api/auth/login",
                                "/api/auth/forgot-password",
                                "/api/auth/reset-password",
                                "/api/auth/register/**",
                                "/api/auth/verify-email",
                                "/api/auth/resend-code").permitAll()

                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()

                        // Category and menu management (open during development/testing)
                        .requestMatchers("/api/categories/**",
                                "/api/food-categories/**",
                                "/api/menu/items/**",
                                "/api/menu-items/**",
                                "/api/uploads/**").permitAll()

                        // Customer, Merchant, Admin CRUD (currently open, you may restrict these later)
                        .requestMatchers("/api/customer/**").permitAll()
                        .requestMatchers("/api/merchant/**").permitAll()
                        .requestMatchers("/api/admin/**").hasRole("ADMIN")

                        // Today's Menu
                        .requestMatchers("/api/menu/today").permitAll()

                        // Top-Up related endpoints
                        .requestMatchers("/api/topup/**").permitAll()

                        // Orders
                        .requestMatchers("/api/orders/place").permitAll()
                        .requestMatchers("/api/orders/customer/**").permitAll()
                        .requestMatchers("/api/orders/merchant/pending").permitAll()
                        .requestMatchers("/api/orders/merchant/*/accept").permitAll()
                        .requestMatchers("/api/orders/merchant/*/complete").permitAll()
                        .requestMatchers("/api/orders/merchant/*/completeDirectly").permitAll()
                        .requestMatchers("/api/orders/*/status").permitAll()
                        .requestMatchers("/api/orders/cancel/**").permitAll()
                        .requestMatchers("/api/orders/**").permitAll()
                        .requestMatchers("/api/orders/merchant/accepted").permitAll()

                        // Messaging endpoints restricted to CUSTOMER or MERCHANT roles
                        .requestMatchers(HttpMethod.POST, "/api/messages/send").hasAnyRole("CUSTOMER", "MERCHANT")
                        .requestMatchers(HttpMethod.GET, "/api/messages/conversation/**").hasAnyRole("CUSTOMER", "MERCHANT")

                        // Uploads public
                        .requestMatchers(HttpMethod.GET, "/api/uploads/**").permitAll()

                        // Any other request requires authentication
                        .anyRequest().authenticated()
                )
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(List.of("http://localhost:8080", "http://localhost:5000")); // Update 5000 if your Flutter port differs
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
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
