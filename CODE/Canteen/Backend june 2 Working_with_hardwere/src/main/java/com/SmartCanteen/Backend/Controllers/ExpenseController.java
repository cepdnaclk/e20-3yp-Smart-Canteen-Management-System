//package com.SmartCanteen.Backend.Controllers;
//
//import com.SmartCanteen.Backend.DTOs.ExpenseRequestDTO;
//import com.SmartCanteen.Backend.DTOs.ExpenseResponseDTO;
//import com.SmartCanteen.Backend.Services.ExpenseService;
//import com.SmartCanteen.Backend.Services.AuthService;
//import lombok.RequiredArgsConstructor;
//import org.springframework.http.ResponseEntity;
//import org.springframework.security.core.annotation.AuthenticationPrincipal;
//import org.springframework.security.core.userdetails.UserDetails;
//import org.springframework.web.bind.annotation.*;
//
//import java.time.LocalDate;
//import java.util.List;
//
//@RestController
//@RequestMapping("/api/customer/expenses")
//@RequiredArgsConstructor
//public class ExpenseController {
//
//    private final ExpenseService expenseService;
//    private final AuthService authService;
//
//    @PostMapping
//    public ResponseEntity<ExpenseResponseDTO> addExpense(
//            @AuthenticationPrincipal UserDetails userDetails,
//            @RequestBody ExpenseRequestDTO dto) {
//        Long customerId = authService.getUserIdFromUserDetails(userDetails);
//        ExpenseResponseDTO response = expenseService.addExpense(customerId, dto);
//        return ResponseEntity.ok(response);
//    }
//
//    @GetMapping("/day")
//    public ResponseEntity<List<ExpenseResponseDTO>> getExpensesForDay(
//            @AuthenticationPrincipal UserDetails userDetails,
//            @RequestParam String date // "YYYY-MM-DD"
//    ) {
//        Long customerId = authService.getUserIdFromUserDetails(userDetails);
//        LocalDate localDate = LocalDate.parse(date);
//        List<ExpenseResponseDTO> expenses = expenseService.getExpensesForDay(customerId, localDate);
//        return ResponseEntity.ok(expenses);
//    }
//
//    @GetMapping
//    public ResponseEntity<List<ExpenseResponseDTO>> getAllExpenses(
//            @AuthenticationPrincipal UserDetails userDetails) {
//        Long customerId = authService.getUserIdFromUserDetails(userDetails);
//        List<ExpenseResponseDTO> expenses = expenseService.getAllExpenses(customerId);
//        return ResponseEntity.ok(expenses);
//    }
//}
