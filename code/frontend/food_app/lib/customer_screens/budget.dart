import 'package:flutter/material.dart';

void main() => runApp(SmartCanteenApp());

class SmartCanteenApp extends StatelessWidget {
  const SmartCanteenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BudgetDashboard(),
    );
  }
}

class BudgetDashboard extends StatefulWidget {
  const BudgetDashboard({super.key});

  @override
  _BudgetDashboardState createState() => _BudgetDashboardState();
}

class _BudgetDashboardState extends State<BudgetDashboard> {
  double totalIncome = 4500;
  double totalExpense = 2176.44;
  double plannedBudget = 4500;
  List<Map<String, dynamic>> expenses = [
    {
      "name": "Lunch",
      "amount": 1700.00,
      "icon": Icons.home,
      "color": Colors.green,
    },
    {
      "name": "Snacks",
      "amount": 126.15,
      "icon": Icons.favorite,
      "color": Colors.pink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    double leftToSpend = totalIncome - totalExpense;
    double spendProgress = totalExpense / plannedBudget;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text("Smart Canteen Budget"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBalanceCard(leftToSpend),
            SizedBox(height: 20),
            _buildProgressBar(leftToSpend, spendProgress),
            SizedBox(height: 20),
            Text(
              "Expenses",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            ...expenses.map((e) => _buildExpenseItem(e)),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Calendar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
        selectedItemColor: Colors.deepPurple,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.deepPurple,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildBalanceCard(double leftToSpend) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Default", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 10),
          Text(
            "\$${leftToSpend.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 32,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_down, color: Colors.red),
                  SizedBox(width: 5),
                  Text(
                    "Expense: \$${totalExpense.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.green),
                  SizedBox(width: 5),
                  Text(
                    "Income: \$${totalIncome.toStringAsFixed(2)}",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(double leftToSpend, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Left to Spend", style: TextStyle(fontWeight: FontWeight.w500)),
        SizedBox(height: 5),
        Text(
          "\$${leftToSpend.toStringAsFixed(2)} out of \$${plannedBudget.toStringAsFixed(2)}",
        ),
        SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreen),
          minHeight: 10,
        ),
      ],
    );
  }

  Widget _buildExpenseItem(Map<String, dynamic> e) {
    return ListTile(
      leading: Icon(e['icon'], color: e['color']),
      title: Text(e['name']),
      trailing: Text("\$${e['amount'].toStringAsFixed(2)}"),
    );
  }
}
