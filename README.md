Consumo De Servicios Con Callbacks Swift
===

### 1. Desarrollo

##### 1.1 Utilidades

Primero necesitamos un par de utilidades. Creamos la classe <i>DGHttpMethods</i>:

Los métodos de http para consumo de servicios.

```swift
public class DGHttpMethods: NSObject {
    public class var GET: String {
        return "GET"
    }
    public class var POST: String {
        return "POST"
    }
}
```

Así también creamos la clase <i>DGUtilities</i>:

Un tiempo de espera máximo para que responda el servicio.
Cabeceras básicas para un consumo de servicios REST.

```swift
public class DGUtilities: NSObject {
    
    public class var TimeOutInterval: TimeInterval {
        return 30.0
    }
    
    public class var BasicHeaderFields: [String: String] {
        return ["Accept": "application/json",
                "Content-Type": "application/json"]
    }
}
```

Y por último creamos un Singleton para reusar la instancía de cadena vacía.

```swift
class DGString {
    
    // Can't init is singleton
    private init() { }
    
    // MARK: Shared Instance
    static let shared = DGString()
    
    // MARK: Local Variable
    var empty = ""
}
```

##### 1.2 Construcción de las capas Request y Submit.

Request es el objeto que contiene nuestra petición, que método, que cabeceras, que cuerpo, cual url, etc.

Y Submit es la capa superior que envia el Request, a través de librerías nativas.

##### 1.2.1 Request

```swift
class Request: Submit {
    
    private func buildRequest(url: String,
                              method: String,
                              extraHeaders: [String: String]? = nil,
                              bodyData: Any? = nil)
        -> URLRequest? {
        
        if let nsurl = URL(string: url) {
            var request = URLRequest(url: nsurl)
            
            if method == DGHttpMethods.POST {
                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: bodyData ?? [], options: [])
                }
                catch let error {
                    print("🔶🔶🔶 Warning :: No se puede castear el body a json...\n body se envía como nil -> commonHttpRest: \(error)")
                    request.httpBody = nil
                }
            }
            
            request.httpMethod          = method
            request.timeoutInterval     = DGUtilities.TimeOutInterval
            request.allHTTPHeaderFields = DGUtilities.BasicHeaderFields
            
            if let headers = extraHeaders, headers.count > 0 {
                for (key, value) in headers {
                    request.addValue(value, forHTTPHeaderField: key)
                }
            }
            
            return request
        }
            
        return nil
    }
    
    internal func httpGet(url: String,
                 extraHeaders: [String: String]? = nil,
                 completion: @escaping (_ error: String, _ json: NSDictionary?) -> Void)
        -> Void {
        
        let requestGet = buildRequest(url: url, method: DGHttpMethods.GET, extraHeaders: extraHeaders)
        
        if let request = requestGet {
            submit(request: request) { (submitError, submitJson) in
                completion(submitError, submitJson)
            }
        } else {
            completion("🔴🔴🔴 ERROR :: Error al crear el Request, posiblemente la urlString sea inválida!!", nil)
        }
    }
    
    internal func httpPost(url: String,
                  extraHeaders: [String: String]? = nil,
                  bodyData: Any? = nil,
                  completion: @escaping (_ error: String, _ json: NSDictionary?) -> Void)
        -> Void {
        
        let requestPost = buildRequest(url: url, method: DGHttpMethods.POST, extraHeaders: extraHeaders, bodyData: bodyData)
        
        if let request = requestPost {
            submit(request: request) { (submitError, submitJson) in
                completion(submitError, submitJson)
            }
        } else {
            completion("🔴🔴🔴 ERROR :: Error al crear el Request, posiblemente la urlString sea inválida!!", nil)
        }
    }
    
}
```

Podemos observar 3 funciones. <i>httpPost</i> y <i>httpGet</i> las cuales obtienen como parametros una URL como cadena, cabeceras extra a parte de las básicas que nos otros le agregamos por defecto, por si lo llegan a necesitar, un <i>body</i> si es una petición <i>post</i> y por último vemos un <i>completion</i> el cual será de utilidad para alguien que invoqué la función pues le regresará (dentro de la misma función) un error en caso de que exista y un json que será la respuesta del servicio solicitado. 

En la implementación vemos que se auxilia de una funcion <i>buildRequest</i> para construir el request, y posterior a eso invoca a otra función <i>submit</i> la cual la obtiene heredando, y es de la que obtiene la respuesta del submite y le pasa a su propio completion esa respuesta, un error en caso de que exista y un json, mismos que seran usados en una capa inferior por el usuario.

Por último la función <i>buildRequest</i> crea un objeto url a partir del string que le pasamos, un request vacio que complementa con un body en caso de que el método sea POST, asigna el método, el tiempo de respuesta, las cabeceras por defecto, en caso de contener cabeceras extra se las agrega y regresa el request.

##### 1.2.2 Submit

Esta es la capa superior y es la que contiene los métodos nativos para el envio del request.

```swift
class Submit: NSObject {
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    
    override init() {
        super.init()
        session = URLSession(configuration: .default)
    }
    
    internal func submit(request: URLRequest,
                completion: @escaping (_ error: String, _ json: NSDictionary?) -> Void)
        -> Void {
        
        dataTask = session?.dataTask(with: request, completionHandler: { (data, response, error) in
            
            guard error == nil else {
                completion("🔴🔴🔴 ERROR :: \(error?.localizedDescription ?? DGString.shared.empty)", nil)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                
                switch httpResponse.statusCode {
                case 200...299:
                    print("🔵🔵🔵 SUCCESS :: Status: \(httpResponse.statusCode)")
                    break
                case 400...499:
                    completion("🔴🔴🔴 ERROR :: Error de comunicaciones, favor de reintentar mas tarde\n...Status Code: \(httpResponse.statusCode)", nil)
                    return
                case 500...599:
                    completion("🔴🔴🔴 ERROR :: Servicio no disponible, favor de reintentar mas tarde\n...Status Code: \(httpResponse.statusCode)", nil)
                    return
                default:
                    completion("🔴🔴🔴 ERROR :: Cuidado, entró en default statusCode: \(httpResponse.statusCode)", nil)
                    return
                }
            }
            else { // Response nil
                completion("🔴🔴🔴 ERROR :: No llego nada del response: \(String(describing: response))", nil)
                return
            }
            if let data = data {
                do {
                    // Puede ser un arreglo
                    if let rawArr = try JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                        let dic: NSDictionary = ["genericList": rawArr]
                        completion(DGString.shared.empty, dic)
                    }
                    else if let rawDic = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        completion(DGString.shared.empty, rawDic)
                    }
                    else {
                        completion("🔴🔴🔴 ERROR :: Error al castear el json", nil)
                    }
                    
                } catch let error {
                    completion("🔴🔴🔴 ERROR :: Cargar Json - \(error.localizedDescription)", nil)
                }
            } else {
                completion("🔴🔴🔴 ERROR :: Data es Nulo", nil)
            }
        })
        dataTask?.resume()
    }
}
```

Se crea una variable <i>session</i> y un <i>dataTask</i> la variable sesssion se inicializa al crear una instalacía de la clase submite y posterior a eso se debe ejecutar la función submite pasandole como parametro el request previamente creado. En base a estos componentes la variable dataTask, ejecutará el servicio (resume) y dentro de la misma función nos dara la respuesta (error, data, response). Al obtener la respuesta checamos que no traiga ningun error (que sea nil). Posterior a eso checamos el response (casteamos a httpResponse) y checamos que se encuentre en el rango de respuestas válido para http que es del 200 ... 299. Si todo va bien ahora sí checamos la data que no sea nil. Una vez superado esto (como es consumo de servicios REST esperamos un JSON o un array de JSONs) intentamos hacer el cast a array, si es así lo envolvemos en un JSON y se lo pasamos a nuestro completion que usara una clase más abajo. Sino se puede hacer el cast a array, lo intentamos hacer a un diccionario que es la estructura de datos que usamos en Swift para manejar los Json y se lo pasamos al completion. Si ninguna de las anteriores se puede regresamos un error en el completion.

##### 1.3 Consumo

En este caso lo hacemos desde nuestro ViewController en el ViewDidLoad. Creamos una instancía de Request y ejecutamos cualquiera de los métodos: httpGet o httpPost.

Para probar podemos usar <a href="https://jsonplaceholder.typicode.com/">JSONPlaceholder</a> que nos da un API REST Dummy.

Para probar POST podemos usar el siguiente ejemplo:

```json
URL:
	https://jsonplaceholder.typicode.com/posts
Headers:
	key: Content-Type, value: application/json
Body:
	 { 
	   "title": "foo",
      "body": "bar",
      "userId": 1
    }
Respuesta:
	{
    "title": "foo",
    "body": "bar",
    "userId": 1,
    "id": 101
	}
```
ViewController:

```swift
class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let r = Request()
       
        r.httpPost(url: "https://jsonplaceholder.typicode.com/posts",
                   bodyData: ["title": "foo", "body": "bar", "userId": 1]) { (requestError, requestJson) in
                    
                    if let json = requestJson {
                        print(json)
                        let body = json["body"] as? String ?? DGString.shared.empty
                        print(body)
                        let title = json["title"] as? String ?? DGString.shared.empty
                        print(title)
                        let userId = json["userId"] as? NSNumber ?? 0
                        print(userId)
                        let id = json["id"] as? NSNumber ?? 0
                        print(id)
                    } else {
                        print(requestError)
                    }
        }

    }

}

```
Posterior a eso, sólo queda llenar nuestros modelos.

### Fuentes

* <a href="https://stackoverflow.com/questions/30401439/how-could-i-create-a-function-with-a-completion-handler-in-swift">How could I create a function with a completion handler in Swift?
</a>






