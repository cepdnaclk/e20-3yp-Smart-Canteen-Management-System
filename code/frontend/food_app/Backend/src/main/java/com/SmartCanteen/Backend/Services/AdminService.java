package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.AdminResponseDTO;
import com.SmartCanteen.Backend.Entities.User;
import com.SmartCanteen.Backend.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;

    public List<AdminResponseDTO> getAllUsers() {
        List<User> users = userRepository.findAll();
        return users.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public AdminResponseDTO getDashboardData() {
        // Implement dashboard data aggregation logic here
        // For now, just return a placeholder
        AdminResponseDTO dto = new AdminResponseDTO();
        dto.setUsername("Admin Dashboard");
        return dto;
    }

    public void updateUserRole(Long userId, String role) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        user.setRole(Enum.valueOf(com.SmartCanteen.Backend.Entities.Role.class, role.toUpperCase()));
        userRepository.save(user);
    }

    private AdminResponseDTO mapToDTO(User user) {
        AdminResponseDTO dto = new AdminResponseDTO();
        dto.setId(user.getId());
        dto.setUsername(user.getUsername());
        dto.setEmail(user.getEmail());
        dto.setFullName(user.getFullName());
        return dto;
    }
}
