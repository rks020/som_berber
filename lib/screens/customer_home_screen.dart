import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/salon_provider.dart';
import 'customer_booking_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SO Yılmaz Berber'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      body: Consumer<SalonProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final barbers = provider.barbers;

          if (barbers.isEmpty) {
            return const Center(child: Text('Aktif berber bulunamadı.'));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Randevu almak istediğiniz berberi seçin',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: barbers.length,
                  itemBuilder: (context, index) {
                    final barber = barbers[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerBookingScreen(barber: barber),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white12,
                              backgroundImage: barber.profilePicturePath != null
                                  ? NetworkImage(barber.profilePicturePath!)
                                  : null,
                              child: barber.profilePicturePath == null
                                  ? const Icon(Icons.person, size: 40)
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              barber.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Randevu Al ➔',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
