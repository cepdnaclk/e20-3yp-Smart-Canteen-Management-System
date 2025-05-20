package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.AdminResponseDTO;
import com.SmartCanteen.Backend.DTOs.AdminUpdateDTO;
import com.SmartCanteen.Backend.Entities.Admin;
import com.SmartCanteen.Backend.Repositories.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final AdminRepository adminRepository;
    private final ModelMapper modelMapper;

    public List<AdminResponseDTO> getAllUsers() {
        List<Admin> users = adminRepository.findAll();
        return users.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public AdminResponseDTO getDashboardData() {
        // Implement actual dashboard data aggregation logic here
        AdminResponseDTO dto = new AdminResponseDTO();
        dto.setUsername("Admin Dashboard");
        return dto;
    }

    public void updateUserRole(Long userId, String role) {
        Admin admin = adminRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        admin.setRole(Enum.valueOf(com.SmartCanteen.Backend.Entities.Role.class, role.toUpperCase()));
        adminRepository.save(admin);
    }

    private AdminResponseDTO mapToDTO(Admin user) {
        return modelMapper.map(user, AdminResponseDTO.class);
    }

    public AdminResponseDTO updateProfile(AdminUpdateDTO updateDTO) {
        Admin admin = getCurrentAuthenticatedAdmin();

        admin.setEmail(updateDTO.getEmail());
        admin.setFullName(updateDTO.getFullName());
        admin.setCardID(updateDTO.getCardID());
        admin.setFingerprintID(updateDTO.getFingerprintID());
        // Add any admin-specific updatable fields here

        adminRepository.save(admin);

        return modelMapper.map(admin, AdminResponseDTO.class);
    }

    public AdminResponseDTO getProfile() {
        Admin admin = getCurrentAuthenticatedAdmin();
        return modelMapper.map(admin, AdminResponseDTO.class);
    }

    public void deleteCurrentAdmin() {
        Admin admin = getCurrentAuthenticatedAdmin();
        adminRepository.delete(admin);
    }

    public Admin getCurrentAuthenticatedAdmin() {
        var authentication = SecurityContextHolder.getContext().getAuthentication();

        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UsernameNotFoundException("No authenticated user found");
        }

        String username = authentication.getName();

        return adminRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Admin not found with username: " + username));
    }
}
