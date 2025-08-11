# Azul SDK

Azul SDK provee acceso a la implementación de Azul Webservices API para aplicaciones que utilizan Ruby como lenguaje de programación.

## Instalación

Para utilizar esta librería puedes correr el siguiente comando:

```bash
gem install azul-sdk
```

Si utilizas Bundler, puedes agregar la siguiente línea a tu archivo `Gemfile`:

```ruby
gem "azul-sdk", require: "azul"
```

## Requerimientos

- Ruby 3.1 o superior

## Configuración

Esta librería necesita ser configurada con las credenciales facilitadas por Servicions Digitales Azul. Los siguientes parametros son configurables:


| Parametro | Tipo | Descripción |
| --- | --- | --- |
| merchant_id | `String` | Identificador del comercio. |
| environment | `String` `Symbol` | Ambiente a utilizar. De este valor dependen los URLs del API a utilizar. <br><br> **Posibles valores: `:development`, `:production`** |
| auth_1 | `String` | Valor de autenticación enviado en el header del requerimiento. |
| auth_2 | `String` | Valor de autenticación enviado en el header del requerimiento. |
| client_certificate | `String` | Certificado del cliente emitido por Azul para la autenticación mutua. |
| client_key | `String` | Llave privada del Certificate Signing Request (CSR) utilizado para la emisión del certificado. |
| client_certificate_path | `String` | Ruta del certificado del cliente en el sistema en caso de preferir utilizar el archivo en lugar del valor. |
| client_key_path | `String` | Ruta de la llave privada del Certificate Signing Request (CSR) en el sistema en caso de preferir utilizar el archivo en lugar del valor. |
| timeout | `Integer` | Tiempo de espera en segundos para las solicitudes. Este valor establece el tiempo máximo que se esperará en las siguientes configuraciones: `ssl_timeout`, `open_timeout`, `read_timeout`, `write_timeout`. <br><br> **Valor por defecto: `120` (120 segundos)** |

Puedes configurar la librería en un initializer llamado `azul.rb`, por ejemplo, si estas utilizando Rails en `config/initializers/azul.rb`:

```ruby
require "azul"

Azul.configure do |config|
  config.merchant_id = ENV.fetch("merchant_id")
  config.auth_1 = ENV.fetch("auth_1")
  config.auth_2 = ENV.fetch("auth_2")
  config.client_certificate = ENV.fetch("client_certificate")
  config.client_key = ENV.fetch("client_key")
  config.environment = "development"
end
```

### Ambientes

Basado en la configuración del ambiente, la librería utilizará los endpoints y credenciales apropiados para cada caso.

- development: `https://pruebas.azul.com.do/WebServices/JSON/Default.aspx`
- production: `https://pagos.azul.com.do/WebServices/JSON/Default.aspx`

## Uso

Los métodos definidos en esta librería permiten interactuar con los servicios web de Azul de manera sencilla. A continuación se presentan algunos ejemplos de uso:

### Transacciones de venta

Esta es la transacción principal utilizada para someter una autorización de una tarjeta.

Las ventas realizadas con la transacción “Sale” son capturadas automáticamente para su liquidación, por lo que sólo pueden ser anuladas con una transacción de “Void” en un lapso de no más de 20 minutos luego de recibir respuesta de aprobación.

Luego de transcurridos estos 20 minutos, la transacción será liquidada y se debe realizar una transacción de “Refund” o devolución para devolver los fondos a la tarjeta.

```ruby
response = Azul::Payment.sale({
  card_number: "411111******1111",
  expiration: "202812",
  cvc: "123",
  amount: 100000,
  itbis: 18000,
})
```

### Transacciones de preautorización (hold)

Se puede separar la autorización del posteo o captura en dos mensajes distintos:

- Hold: preautorización y reserva de los fondos en la tarjeta del cliente.
- Post: se hace la captura o el “posteo” de la transacción.

```ruby
response = Azul::Payment.hold({
  card_number: "411111******1111",
  expiration: "202812",
  cvc: "123",
  amount: 100000,
  itbis: 18000,
})
```

### Transacciones de captura (posteo) de una preautorización (hold)

Permita capurar una preautorización (hold) previamente realizada para su liquidación. 

```ruby
response = Azul::Payment.capture({
  azul_order_id: "44772511",
  amount: 100000,
  itbis: 18000,
})
```

### Transacciones para anular ventas, capturas (posteo) o preautorizaciones (hold)

Las transacciones de venta o post se pueden anular antes de los 20 minutos de haber recibido la respuesta de aprobación. Las transacciones de hold que no han sido posteadas no tienen límite de tiempo para anularse.

```ruby
response = Azul::Payment.void({ azul_order_id: "44772511" })
```

### Transacciones de devolución (refund)

La devolución (refund) permite reembolsarle los fondos a una tarjeta luego de haberse
liquidado la transacción.

Para poder realizar una devolución se debe haber procesado exitosamente una transacción de venta o captura y se deben utilizar los datos de la transacción original para enviar la devolución.

- El monto a devolver puede ser el mismo o menor.
- Se permite hacer una devolución, múltiples devoluciones o devoluciones parciales para cada transacción realizada.

```ruby
response = Azul::Refund.create({
  azul_order_id: "44772511",
  amount: 100000,
  itbis: 18000,
})
```

### Verificación de transacciones (verify)

Este método permite verificar la respuesta enviada por el webservice de una transacción anterior, identificada por el campo `custom_order_id`.

```ruby
response = Azul::Transaction.verify({ custom_order_id: "123456789" })
```

### Consulta de transacciones (search)

Este método permite extraer los detalles de una o varias transacciones anteriormente procesadas de un rango de fechas previamente establecido.

```ruby
response = Azul::Transaction.search({
  date_from: "2025-08-01",
  date_to: "2025-08-31"
})
```

### Objeto de respuesta y atributos (response)

Todos estos métodos devuelven una instancia [`Azul::Response`](lib/azul/response.rb) que representa la respuesta del API y contiene información sobre la transacción procesada.

Se puede utilizar `accessors` para leer los atributos de la respuesta de manera sencilla. Si el atributo no existe, retornará `nil`.

```ruby

response = Azul::Payment.sale({
  card_number: "411111******1111",
  expiration: "202812",
  cvc: "123",
  amount: 100000,
  itbis: 18000,
  custom_order_id: "xyz11001"
})

puts response.azul_order_id # "44772544"
puts response.response_code # "ISO8583"
puts response.response_message # "APROBADA"
puts response.raw_response # <Net::HTTPOK:0x0000ffff603cc458>
puts response.body

# {
#   "AuthorizationCode"=>"OK2930",
#   "AzulOrderId"=>"44772544",
#   "CountryCode"=>"SGP",
#   "CustomOrderId"=>"xyz11001",
#   "DateTime"=>"20250808155452",
#   "ErrorDescription"=>"",
#   "IsoCode"=>"00",
#   "LotNumber"=>"",
#   "RRN"=>"2025080815545644772544",
#   "ResponseCode"=>"ISO8583",
#   "ResponseCodeThreeDS"=>"4",
#   "ResponseMessage"=>"APROBADA",
#   "Ticket"=>"1"
# }
```

### Objeto de requerimiento (request)

A través del objeto de respuesta `response.request` se puede acceder a los datos enviados en la solicitud original para su revisión.

El objeto de requerimiento (request) contiene las siguientes propiedades:

| Nombre | Tipo | Descripción |
| --- | --- | --- |
| api_url | `String` | URL del API al que se envió la solicitud. |
| headers | `Hash` | Encabezados HTTP enviados en la solicitud. |
| method | `Symbol` | Método HTTP utilizado en la solicitud. |
| params | `Hash` | Parámetros enviados en la solicitud. |
| payment_method_metadata | `Hash` | Metadatos del método de pago utilizado. |

```ruby
puts response.request.api_url
# https://pruebas.azul.com.do/WebServices/JSON/Default.aspx

puts response.request.headers
# { "Content-Type": "application/json", "User-Agent"=>"Ruby" }, "Auth1"=>"...", "Auth2"=>"..."

puts response.request.method
# :post

puts response.request.params
# { "card_number": "4111********1111", "expiration": "[FILTERED]", "cvc": "[FILTERED]", "amount": 100000, "itbis": 18000, "custom_order_id": "xyz11001" }

puts response.request.payment_method_metadata
# {:last4=>"0117", :brand=>"Visa", :exp_month=>"12", :exp_year=>"2028"}
```

### Requerimientos exitosos

Para considerar una respuesta como exitosa, se considera que el atributo `iso_code` debe ser igual a `"00"`, `"3D"` o `"3D2METHOD"` o que el attributo `response_message` sea igual a `"APROBADA"`.

En el caso de consultas de transacciones (search), se considera exitosa si el attributo `response_code` es igual a `"SEARCHED"`.

### Errores (Errors)

Cuando el API retorna un error o el atributo `iso_code` no es considerado exitoso, se lanza una excepción basada en los valores retornados en los campos `iso_code` y `error_description`.

| Códigos de error | Descripción | Clase de Excepción |
| --- | --- | --- |
| "03", "04", "05", "07", "12", "13", "14", "41", "43", "46", "51", "54", "57", "59", "61", "62", "63", "82", "83", "91" | Códigos de respuesta del banco emisor o procesador | [`Azul::DeclineError`](lib/azul/errors.rb) |
| "99" | Error de procesamiento | [`Azul::ProcessingError`](lib/azul/errors.rb) |
| "08", "3D" | Error de autenticación | [`Azul::AuthenticationError`](lib/azul/errors.rb) |
| "" | Error sin `iso_code` | [`Azul::ApiError`](lib/azul/errors.rb) |

```ruby
begin
  response = Azul::Payment.sale({
    card_number: "411111******1111",
    expiration: "202812",
    amount: 100000,
    itbis: 18000,
  })
rescue Azul::ApiError => e
  puts e.message # "Azul API Error: VALIDATION_ERROR:CVC - "
  puts e.response.body # Azul API response parsed from JSON
end
```

## Mapeo de Parámetros

La siguiente tabla muestra el mapeo entre los parámetros utilizados en esta librería y los esperados por el API de Azul:

| Parámetro Ruby | Parámetro API | Tipo | Descripción |
| --- | --- | --- | --- |
| `card_number` | `CardNumber` | `String` | Número de tarjeta a la cual se le ha de cargar la transacción |
| `expiration` | `Expiration` | `String` | Fecha expiración/vencimiento de la tarjeta (formato: YYYYMM) |
| `cvc` | `CVC` | `String` | Código de seguridad de la tarjeta (CVV2 o CVC) |
| `amount` | `Amount` | `String` | Monto total de la transacción (Impuestos incluidos) en centavos |
| `itbis` | `Itbis` | `String` | Valor del ITBIS en centavos |
| `trx_type` | `TrxType` | `String` | Tipo de transacción (Sale, Hold, Refund) |
| `order_number` | `OrderNumber` | `String` | Número de orden asociado a la transacción |
| `customer_service_phone` | `CustomerServicePhone` | `String` | Número de servicio para atención telefónica del establecimiento |
| `ecommerce_url` | `ECommerceURL` | `String` | Dirección web del afiliado |
| `custom_order_id` | `CustomOrderId` | `String` | Número identificador dado por el afiliado a la transacción |
| `alt_merchant_name` | `AltMerchantName` | `String` | Nombre más descriptivo para que el tarjetahabiente pueda identificar en su estado de cuenta |
| **`apple_pay`** | **`ApplePay`** | **`String`** | **Indica si se usa Apple Pay** |
| └─ `payment_token` | `PaymentToken` | `String` | Token de pago |
| `cryptogram` | `Cryptogram` | `String` | Criptograma para pagos tokenizados |
| `eci_indicator` | `ECIIndicator` | `String` | Indicador ECI (Electronic Commerce Indicator) |
| **`google_pay`** | **`GooglePay`** | **`String`** | **Indica si se usa Google Pay** |
| └─ `payment_token` | `PaymentToken` | `String` | Token de pago |
| `data_vault_token` | `DataVaultToken` | `String` | Token generado por Azul para transacciones con token |
| `save_to_data_vault` | `SaveToDataVault` | `String` | Valores posibles 1 = si, 0 = no. Para generar token |
| `force_no_3ds` | `ForceNo3DS` | `String` | Valores posibles 0 = no, 1 = si. Fuerza transacción sin 3D Secure |
| **`three_ds_auth`** | **`ThreeDSAuth`** | **`Hash`** | **Parámetros de autenticación 3D Secure** |
| ├─ `term_url` | `TermUrl` | `String` | URL de retorno después de 3D Secure |
| ├─ `method_notification_url` | `MethodNotificationUrl` | `String` | URL de notificación del método 3D Secure |
| └─ `requestor_challenge_indicator` | `RequestorChallengeIndicator` | `String` | Indicador de desafío del solicitante |
| **`card_holder_info`** | **`CardHolderInfo`** | **`Hash`** | **Información del tarjetahabiente** |
| ├─ `name` | `Name` | `String` | Nombre del tarjetahabiente |
| ├─ `email` | `Email` | `String` | Email del tarjetahabiente |
| └─ `phone_mobile` | `PhoneMobile` | `String` | Teléfono móvil del tarjetahabiente |
| **`browser_info`** | **`BrowserInfo`** | **`Hash`** | **Información del navegador** |
| ├─ `accept_header` | `AcceptHeader` | `String` | Encabezado Accept del navegador |
| ├─ `ip_address` | `IPAddress` | `String` | Dirección IP del cliente |
| ├─ `user_agent` | `UserAgent` | `String` | User Agent del navegador |
| ├─ `language` | `Language` | `String` | Idioma del navegador |
| ├─ `color_depth` | `ColorDepth` | `String` | Profundidad de color de la pantalla |
| ├─ `screen_width` | `ScreenWidth` | `String` | Ancho de pantalla en píxeles |
| ├─ `screen_height` | `ScreenHeight` | `String` | Alto de pantalla en píxeles |
| ├─ `time_zone` | `TimeZone` | `String` | Zona horaria del navegador |
| └─ `javascript_enable` | `JavaScriptEnable` | `String` | Indica si JavaScript está habilitado |
| `method_notification_status` | `MethodNotificationStatus` | `String` | Estado de notificación del método 3D Secure |
| `cres` | `CRes` | `String` | Respuesta del desafío (Challenge Response) de 3D Secure |
| `original_date` | `OriginalDate` | `String` | Fecha de la transacción original (formato: YYYYMMDD) |
| `original_trx_ticket_nr` | `OriginalTrxTicketNr` | `String` | Número de ticket de la transacción original |
| `azul_order_id` | `AzulOrderId` | `String` | ID de orden generado por Azul |
| `response_code` | `ResponseCode` | `String` | Código de respuesta de la transacción |
| `rrn` | `RRN` | `String` | Número de referencia (Reference Referral Number) |
| `date_from` | `DateFrom` | `String` | Fecha inicial para búsqueda de transacciones |
| `date_to` | `DateTo` | `String` | Fecha final para búsqueda de transacciones |
| `acquirer_ref_data` | `AcquirerRefData` | `String` | Uso interno Azul. Valor fijo: 1 |

### Uso de parámetros anidados

Para los parámetros de tipo `Hash` (`three_ds_auth`, `card_holder_info`, `browser_info`, `apple_pay`, `google_pay`), se deben pasar los valores anidados como un hash:

```ruby
response = Azul::Payment.sale({
  card_number: "411111******1111",
  expiration: "202812",
  cvc: "123",
  amount: 100000,
  itbis: 18000,
  three_ds_auth: {
    term_url: "https://example.com/return",
    method_notification_url: "https://example.com/notify",
    requestor_challenge_indicator: "01"
  },
  card_holder_info: {
    name: "Juan Pérez",
    email: "juan@example.com",
    phone_mobile: "8095551234"
  },
  browser_info: {
    accept_header: "text/html",
    ip_address: "192.168.1.1",
    user_agent: "Mozilla/5.0...",
    language: "es-ES",
    color_depth: "24",
    screen_width: "1920",
    screen_height: "1080",
    time_zone: "-240",
    javascript_enable: "1"
  }
})
```
