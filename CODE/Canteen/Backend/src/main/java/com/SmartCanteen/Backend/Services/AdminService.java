package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.AdminResponseDTO;
import com.SmartCanteen.Backend.DTOs.AdminUpdateDTO;
import com.SmartCanteen.Backend.Entities.Admin;
import com.SmartCanteen.Backend.Repositories.AdminRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.security.core.Authentication;
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

    // Fetch all admins
    public List<AdminResponseDTO> getAllAdmins() {
        List<Admin> admins = adminRepository.findAll();
        return admins.stream()
                .map(this::mapToDTO)
                .collect(Collectors.toList());
    }

    public AdminResponseDTO getDashboardData() {
        AdminResponseDTO dto = new AdminResponseDTO();
        dto.setUsername("Admin Dashboard");
        // Add more dashboard data as needed
        return dto;
    }

    public void updateUserRole(Long adminId, String role) {
        Admin admin = adminRepository.findById(adminId)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        admin.setRole(Enum.valueOf(com.SmartCanteen.Backend.Entities.Role.class, role.toUpperCase()));
        adminRepository.save(admin);
    }

    private AdminResponseDTO mapToDTO(Admin admin) {
        return modelMapper.map(admin, AdminResponseDTO.class);
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
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new UsernameNotFoundException("No authenticated user found");
        }
        String principal = authentication.getName();
        // Use findByEmail if you've updated UserPrincipal to use email as principal
        return adminRepository.findByEmail(principal)
                .or(() -> adminRepository.findByEmail(principal))
                .orElseThrow(() -> new UsernameNotFoundException("Admin not found with principal: " + principal));
    }
}
