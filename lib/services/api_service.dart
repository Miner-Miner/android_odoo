import 'package:mobilepos/models/assignment_response.dart';
import 'package:mobilepos/models/login_response.dart';
import 'package:mobilepos/models/sale_request.dart';
import 'package:mobilepos/models/sale_response.dart';
import 'package:mobilepos/static/api.dart';
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../models/product.dart';

part 'api_service.g.dart';

@RestApi()
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @GET(get_all_pos_data_url)
  Future<ProductResponse> getProducts();

  @POST(login_url)
  Future<LoginResponse> login(@Body() Map<String, dynamic> body);

  @POST(create_sale_order_url)
  Future<SaleOrderResponse> createSaleOrder(@Body() Map<String, dynamic> request);

  @POST(get_assignment_by_userid)
  Future<AssignmentResponse> getAssignments(@Body() Map<String, dynamic> body);
}