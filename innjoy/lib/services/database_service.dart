import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

// Import all modular services
import 'package:login_page/services/database/base_database_service.dart';
import 'package:login_page/services/database/hotel_service.dart';
import 'package:login_page/services/database/user_data_service.dart';
import 'package:login_page/services/database/restaurant_service.dart';
import 'package:login_page/services/database/room_service_service.dart';
import 'package:login_page/services/database/housekeeping_service.dart';
import 'package:login_page/services/database/event_service.dart';
import 'package:login_page/services/database/reservation_service.dart';
import 'package:login_page/services/database/spa_service.dart';
import 'package:login_page/services/database/emergency_service.dart';

/// DatabaseService - FACADE pattern implementation.
/// Delegates all operations to modular domain-specific services.
/// Maintains backward compatibility - all existing code continues to work.
class DatabaseService extends BaseDatabaseService {
  // Singleton instance
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Sub-services (lazy initialization via factory constructors)
  final _hotelService = HotelService();
  final _userDataService = UserDataService();
  final _restaurantService = RestaurantService();
  final _roomServiceService = RoomServiceService();
  final _housekeepingService = HousekeepingService();
  final _eventService = EventService();
  final _reservationService = ReservationService();
  final _spaService = SpaService();
  final _emergencyService = EmergencyService();

  // ============================================================
  // HOTEL SERVICE DELEGATION
  // ============================================================

  Stream<List<Map<String, dynamic>>> getHotels() => _hotelService.getHotels();

  Future<void> createHotel(String hotelName, Map<String, dynamic> data) =>
      _hotelService.createHotel(hotelName, data);

  Stream<Map<String, dynamic>?> getHotelWifiInfo(String hotelName) =>
      _hotelService.getHotelWifiInfo(hotelName);

  Future<void> updateHotelWifiInfo(
    String hotelName,
    String ssid,
    String password,
  ) => _hotelService.updateHotelWifiInfo(hotelName, ssid, password);

  Future<bool> restoreHotelFromSubcollection(String hotelName) =>
      _hotelService.restoreHotelFromSubcollection(hotelName);

  Stream<Map<String, dynamic>?> getHotelInfo(String hotelName) =>
      _hotelService.getHotelInfo(hotelName);

  Future<void> seedDefaultServices(String hotelName) =>
      _hotelService.seedDefaultServices(hotelName);

  // ============================================================
  // USER DATA SERVICE DELEGATION
  // ============================================================

  Future<Map<String, dynamic>?> getUserData(String userId) =>
      _userDataService.getUserData(userId);

  Stream<Map<String, dynamic>?> getUserStream(String userId) =>
      _userDataService.getUserStream(userId);

  Future<void> saveUserdata(
    String uid,
    String email,
    String name, {
    String role = 'customer',
  }) => _userDataService.saveUserdata(uid, email, name, role: role);

  Future<Map<String, dynamic>?> getUser(String uid) =>
      _userDataService.getUser(uid);

  Future<List<String>> getUserInterests() =>
      _userDataService.getUserInterests();

  Future<void> updateUserInterests(List<String> interests) =>
      _userDataService.updateUserInterests(interests);

  Future<String> getUserRoomNumber() => _userDataService.getUserRoomNumber();

  // ============================================================
  // RESTAURANT SERVICE DELEGATION
  // ============================================================

  Stream<List<Map<String, dynamic>>> getRestaurants(String hotelName) =>
      _restaurantService.getRestaurants(hotelName);

  Stream<List<MenuItem>> getRestaurantMenu(
    String hotelName,
    String restaurantId,
  ) => _restaurantService.getRestaurantMenu(hotelName, restaurantId);

  Future<void> addMenuItem(
    String hotelName,
    String restaurantId,
    MenuItem item,
  ) => _restaurantService.addMenuItem(hotelName, restaurantId, item);

  Future<void> updateMenuItem(
    String hotelName,
    String restaurantId,
    String itemId,
    MenuItem item,
  ) => _restaurantService.updateMenuItem(hotelName, restaurantId, itemId, item);

  Future<void> deleteMenuItem(
    String hotelName,
    String restaurantId,
    String itemId,
  ) => _restaurantService.deleteMenuItem(hotelName, restaurantId, itemId);

  Stream<Map<String, dynamic>?> getRestaurantSettings(
    String hotelName,
    String restaurantId,
  ) => _restaurantService.getRestaurantSettings(hotelName, restaurantId);

  Future<void> updateRestaurantSettings(
    String hotelName,
    String restaurantId,
    Map<String, dynamic> data,
  ) => _restaurantService.updateRestaurantSettings(
    hotelName,
    restaurantId,
    data,
  );

  Future<Map<String, dynamic>> makeReservation(
    String hotelName,
    String restaurantId,
    String restaurantName,
    DateTime date,
    int partySize,
    String note,
  ) => _restaurantService.makeReservation(
    hotelName,
    restaurantId,
    restaurantName,
    date,
    partySize,
    note,
  );

  Stream<List<Map<String, dynamic>>> getUserReservations(
    String userId, {
    String? hotelName,
  }) => _restaurantService.getUserReservations(userId, hotelName: hotelName);

  Stream<List<Map<String, dynamic>>> getRestaurantReservations(
    String hotelName,
    String restaurantId,
  ) => _restaurantService.getRestaurantReservations(hotelName, restaurantId);

  // ============================================================
  // ROOM SERVICE DELEGATION
  // ============================================================

  Stream<List<MenuItem>> getRoomServiceMenu(String hotelName) =>
      _roomServiceService.getRoomServiceMenu(hotelName);

  Future<void> addRoomServiceMenuItem(String hotelName, MenuItem item) =>
      _roomServiceService.addRoomServiceMenuItem(hotelName, item);

  Future<void> updateRoomServiceMenuItem(
    String hotelName,
    String itemId,
    MenuItem item,
  ) => _roomServiceService.updateRoomServiceMenuItem(hotelName, itemId, item);

  Future<void> deleteRoomServiceMenuItem(String hotelName, String itemId) =>
      _roomServiceService.deleteRoomServiceMenuItem(hotelName, itemId);

  Future<void> placeRoomServiceOrder(
    String hotelName,
    String roomNumber,
    String guestName,
    List<Map<String, dynamic>> items,
    double totalPrice,
  ) => _roomServiceService.placeRoomServiceOrder(
    hotelName,
    roomNumber,
    guestName,
    items,
    totalPrice,
  );

  Stream<Map<String, dynamic>?> getMySpending(String hotelName) =>
      _roomServiceService.getMySpending(hotelName);

  Stream<List<Map<String, dynamic>>> getAllRoomServiceOrders(
    String hotelName,
  ) => _roomServiceService.getAllRoomServiceOrders(hotelName);

  Stream<List<Map<String, dynamic>>> getMyRoomServiceOrders(String hotelName) =>
      _roomServiceService.getMyRoomServiceOrders(hotelName);

  Stream<List<Map<String, dynamic>>> getRooms(String hotelName) =>
      _roomServiceService.getRooms(hotelName);

  Stream<DocumentSnapshot> getRoomStream(String documentId) =>
      _roomServiceService.getRoomStream(documentId);

  // ============================================================
  // HOUSEKEEPING SERVICE DELEGATION
  // ============================================================

  Future<void> requestHousekeeping(String requestType, String note) =>
      _housekeepingService.requestHousekeeping(requestType, note);

  Stream<List<Map<String, dynamic>>> getHotelHousekeepingRequests(
    String hotelName,
  ) => _housekeepingService.getHotelHousekeepingRequests(hotelName);

  Stream<List<Map<String, dynamic>>> getMyHousekeepingRequests(
    String hotelName,
  ) => _housekeepingService.getMyHousekeepingRequests(hotelName);

  Future<void> archiveHousekeepingRequestsForRoom(
    String hotelName,
    String roomNumber,
  ) => _housekeepingService.archiveHousekeepingRequestsForRoom(
    hotelName,
    roomNumber,
  );

  // ============================================================
  // EVENT SERVICE DELEGATION
  // ============================================================

  Stream<List<Map<String, dynamic>>> getHotelEvents(String hotelName) =>
      _eventService.getHotelEvents(hotelName);

  Future<String> addEvent(String hotelName, Map<String, dynamic> eventData) =>
      _eventService.addEvent(hotelName, eventData);

  Future<void> updateEvent(
    String hotelName,
    String eventId,
    Map<String, dynamic> eventData,
  ) => _eventService.updateEvent(hotelName, eventId, eventData);

  Future<void> deleteEvent(String hotelName, String eventId) =>
      _eventService.deleteEvent(hotelName, eventId);

  Stream<List<Map<String, dynamic>>> getEventParticipants(
    String hotelName,
    String eventId,
  ) => _eventService.getEventParticipants(hotelName, eventId);

  Future<Map<String, dynamic>> registerForEvent(
    String hotelName,
    String eventId,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> eventDetails,
  ) => _eventService.registerForEvent(
    hotelName,
    eventId,
    userInfo,
    eventDetails,
  );

  Stream<List<Map<String, dynamic>>> getUserEvents(
    String userId, {
    String? hotelName,
  }) => _eventService.getUserEvents(userId, hotelName: hotelName);

  Stream<QuerySnapshot> listenForInterestEvents(
    String hotelName,
    List<String> interests,
  ) => _eventService.listenForInterestEvents(hotelName, interests);

  // ============================================================
  // RESERVATION SERVICE DELEGATION
  // ============================================================

  Future<String> createReservation(
    String hotelName,
    String roomNumber,
    String guestName,
    DateTime checkInDate,
    DateTime checkOutDate,
  ) => _reservationService.createReservation(
    hotelName,
    roomNumber,
    guestName,
    checkInDate,
    checkOutDate,
  );

  Stream<List<Map<String, dynamic>>> getHotelReservations(String hotelName) =>
      _reservationService.getHotelReservations(hotelName);

  Future<bool> verifyAndRedeemPnr(
    String pnr,
    String selectedHotel,
    String userId,
  ) => _reservationService.verifyAndRedeemPnr(pnr, selectedHotel, userId);

  Future<void> updateReservationStatus(
    String hotelName,
    String roomNumber,
    String status,
  ) => _reservationService.updateReservationStatus(
    hotelName,
    roomNumber,
    status,
  );

  Future<void> deleteReservation(String hotelName, String roomNumber) =>
      _reservationService.deleteReservation(hotelName, roomNumber);

  // ============================================================
  // SPA SERVICE DELEGATION
  // ============================================================

  Stream<Map<String, dynamic>?> getSpaInfo(String hotelName) =>
      _spaService.getSpaInfo(hotelName);

  Stream<Map<String, dynamic>?> getFitnessInfo(String hotelName) =>
      _spaService.getFitnessInfo(hotelName);

  Future<void> bookSpaAppointment({
    required String serviceName,
    required String duration,
    required double price,
    required DateTime appointmentDate,
    required String timeSlot,
    required String paymentMethod,
  }) => _spaService.bookSpaAppointment(
    serviceName: serviceName,
    duration: duration,
    price: price,
    appointmentDate: appointmentDate,
    timeSlot: timeSlot,
    paymentMethod: paymentMethod,
  );

  Stream<List<String>> getSpaBookedSlots(String hotelName, DateTime date) =>
      _spaService.getSpaBookedSlots(hotelName, date);

  Stream<List<Map<String, dynamic>>> getSpaReservations(String hotelName) =>
      _spaService.getSpaReservations(hotelName);

  Future<void> updateSpaReservationStatus(
    String hotelName,
    String reservationId,
    String status,
  ) => _spaService.updateSpaReservationStatus(hotelName, reservationId, status);

  Future<void> addSpaService(
    String hotelName,
    Map<String, dynamic> serviceData,
  ) => _spaService.addSpaService(hotelName, serviceData);

  Future<void> updateSpaService(
    String hotelName,
    String docId,
    Map<String, dynamic> serviceData,
  ) => _spaService.updateSpaService(hotelName, docId, serviceData);

  Future<void> deleteSpaService(String hotelName, String docId) =>
      _spaService.deleteSpaService(hotelName, docId);

  Stream<List<Map<String, dynamic>>> getSpaMenu(String hotelName) =>
      _spaService.getSpaMenu(hotelName);

  Stream<List<Map<String, dynamic>>> getUserSpaAppointments(
    String userId, {
    String? hotelName,
  }) => _spaService.getUserSpaAppointments(userId, hotelName: hotelName);

  Future<void> migrateSpaServicesToNewStructure(String hotelName) =>
      _spaService.migrateSpaServicesToNewStructure(hotelName);

  // ============================================================
  // EMERGENCY SERVICE DELEGATION
  // ============================================================

  Future<void> sendEmergencyAlert({
    required String emergencyType,
    required String roomNumber,
    required String locationContext,
  }) => _emergencyService.sendEmergencyAlert(
    emergencyType: emergencyType,
    roomNumber: roomNumber,
    locationContext: locationContext,
  );
}
