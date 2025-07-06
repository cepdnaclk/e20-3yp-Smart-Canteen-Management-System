package com.SmartCanteen.Backend.Controllers;

import com.SmartCanteen.Backend.DTOs.SalesReportDTO;
import com.SmartCanteen.Backend.Services.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/merchant/reports")
@RequiredArgsConstructor
@PreAuthorize("hasRole('MERCHANT')")
public class ReportController {

    private final ReportService reportService;

    @GetMapping("/sales/daily")
    public ResponseEntity<SalesReportDTO> getDailySalesReport(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        SalesReportDTO report = reportService.generateDailySalesReport(date);
        return ResponseEntity.ok(report);
    }

    @GetMapping("/sales/monthly")
    public ResponseEntity<SalesReportDTO> getMonthlySalesReport(
            @RequestParam int year,
            @RequestParam int month) {
        SalesReportDTO report = reportService.generateMonthlySalesReport(year, month);
        return ResponseEntity.ok(report);
    }
}