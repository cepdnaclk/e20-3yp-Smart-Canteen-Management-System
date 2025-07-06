package com.SmartCanteen.Backend.Services;

import com.SmartCanteen.Backend.DTOs.OrderDTO;
import com.SmartCanteen.Backend.DTOs.SalesReportDTO;
import com.SmartCanteen.Backend.Entities.MenuItem;
import com.SmartCanteen.Backend.Entities.Merchant;
import com.SmartCanteen.Backend.Entities.Order;
import com.SmartCanteen.Backend.Entities.Role;
import com.SmartCanteen.Backend.Repositories.MenuItemRepository;
import com.SmartCanteen.Backend.Repositories.OrderRepository;
import com.SmartCanteen.Backend.Repositories.UserRepository;
import lombok.RequiredArgsConstructor;
import org.modelmapper.ModelMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReportService {

    private final OrderRepository orderRepository;
    private final MenuItemRepository menuItemRepository;
    private final UserRepository userRepository;
    private final MerchantService merchantService;
    private final ModelMapper modelMapper;

    public SalesReportDTO generateDailySalesReport(LocalDate date) {
        Merchant merchant = merchantService.getCurrentAuthenticatedMerchant();
        List<Order> completedOrders = orderRepository.findCompletedOrdersByMerchantAndDate(merchant.getId(), date);
        return buildReportFromOrders(completedOrders);
    }

    public SalesReportDTO generateMonthlySalesReport(int year, int month) {
        Merchant merchant = merchantService.getCurrentAuthenticatedMerchant();
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        List<Order> completedOrders = orderRepository.findCompletedOrdersByMerchantAndDateRange(merchant.getId(), startDate, endDate);
        return buildReportFromOrders(completedOrders);
    }

    public SalesReportDTO generatePlatformSalesReport(LocalDate startDate, LocalDate endDate) {
        List<Order> completedOrders = orderRepository.findCompletedOrdersByDateRange(startDate, endDate);
        return buildReportFromOrders(completedOrders);
    }

    public Map<String, Long> getPlatformStats() {
        long customerCount = userRepository.countByRole(Role.CUSTOMER);
        long merchantCount = userRepository.countByRole(Role.MERCHANT);
        long adminCount = userRepository.countByRole(Role.ADMIN);
        return Map.of(
                "totalCustomers", customerCount,
                "totalMerchants", merchantCount,
                "totalAdmins", adminCount
        );
    }

    private SalesReportDTO buildReportFromOrders(List<Order> orders) {
        BigDecimal totalSales = orders.stream()
                .map(Order::getTotalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        BigDecimal totalCost = calculateTotalCost(orders);

        List<OrderDTO> orderDTOs = orders.stream()
                .map(order -> modelMapper.map(order, OrderDTO.class))
                .collect(Collectors.toList());

        return SalesReportDTO.builder()
                .totalSales(totalSales)
                .totalCost(totalCost)
                .totalProfit(totalSales.subtract(totalCost))
                .totalOrders(orders.size())
                .orders(orderDTOs)
                .build();
    }

    private BigDecimal calculateTotalCost(List<Order> orders) {
        BigDecimal totalCost = BigDecimal.ZERO;

        List<Long> allMenuItemIds = orders.stream()
                .flatMap(order -> order.getItems().keySet().stream())
                .distinct()
                .toList();

        Map<Long, MenuItem> menuItemMap = menuItemRepository.findAllById(allMenuItemIds).stream()
                .collect(Collectors.toMap(MenuItem::getId, item -> item));

        for (Order order : orders) {
            for (Map.Entry<Long, Integer> entry : order.getItems().entrySet()) {
                long menuItemId = entry.getKey();
                Integer quantity = entry.getValue();
                MenuItem menuItem = menuItemMap.get(menuItemId);
                if (menuItem != null && menuItem.getCostPrice() != null) {
                    totalCost = totalCost.add(menuItem.getCostPrice().multiply(BigDecimal.valueOf(quantity)));
                }
            }
        }
        return totalCost;
    }
}