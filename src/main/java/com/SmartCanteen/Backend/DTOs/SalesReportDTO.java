package com.SmartCanteen.Backend.DTOs;

import lombok.Builder;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;

@Data
@Builder
public class SalesReportDTO {
    private BigDecimal totalSales;
    private BigDecimal totalCost;
    private BigDecimal totalProfit;
    private int totalOrders;
    private List<OrderDTO> orders;
}