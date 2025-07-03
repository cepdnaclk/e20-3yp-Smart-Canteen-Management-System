package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.CustomerDTO;
import com.SmartCanteen.Backend.DTOs.MerchantDTO;
import com.SmartCanteen.Backend.Entities.User;
import com.SmartCanteen.Backend.Exceptions.ResourceNotFoundException;
import com.SmartCanteen.Backend.Repositories.CustomerRepository;
import com.SmartCanteen.Backend.Repositories.MerchantRepository;
import com.SmartCanteen.Backend.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class UserManagementService {

    private final UserRepository userRepository;
    private final CustomerRepository customerRepository;
    private final MerchantRepository merchantRepository;
    private final ModelMapper modelMapper;

    @Transactional(readOnly = true)
    public List<CustomerDTO> getAllCustomers() {
        return customerRepository.findAll().stream()
                .map(customer -> modelMapper.map(customer, CustomerDTO.class))
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<MerchantDTO> getAllMerchants() {
        return merchantRepository.findAll().stream()
                .map(merchant -> modelMapper.map(merchant, MerchantDTO.class))
                .collect(Collectors.toList());
    }

    public User deactivateUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
        user.setActive(false);
        return userRepository.save(user);
    }

    public User activateUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found with id: " + userId));
        user.setActive(true);
        return userRepository.save(user);
    }
}