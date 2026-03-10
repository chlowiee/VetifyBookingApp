import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'database/db_helper.dart';

/// ---------------- MODELOS ----------------
class Usuario {
  final String id;
  String nombre;
  String email;
  String rol;
  String? foto; 

  Usuario({required this.id, required this.nombre, required this.email, this.rol = 'cliente', this.foto,});
}

class Mascota {
  final String id;
  String nombre;
  String especie;
  String raza;
  String edad;
  String peso;
  String sexo;
  String color;

  Mascota({
    required this.id,
    required this.nombre,
    required this.especie,
    required this.raza,
    required this.edad,
    required this.peso,
    required this.sexo,
    required this.color,
  });
}

class Cita {
  final String id;
  final String clienteId;
  final String mascotaId;
  DateTime fecha;
  String veterinario;
  String servicio;
  String estado;

  Cita({
    required this.id,
    required this.clienteId,
    required this.mascotaId,
    required this.fecha,
    required this.veterinario,
    required this.servicio,
    this.estado = 'Pendiente',
  });
}

/// ---------------- PROVIDER ----------------
class AppProvider with ChangeNotifier {
  List<Usuario> usuarios = [];
  List<Mascota> mascotas = [];
  List<Cita> citas = [];
  Usuario? usuarioActual;

Future registrarUsuario(Usuario usuario) async {

  final db = await DBHelper.database;

  await db.insert('usuarios', {
    'id': usuario.id,
    'nombre': usuario.nombre,
    'email': usuario.email,
  });

  usuarios.add(usuario);
  notifyListeners();
}

  Future<bool> login(String email) async {

  final db = await DBHelper.database;

  final result = await db.query(
    'usuarios',
    where: 'email = ?',
    whereArgs: [email],
  );

  if (result.isEmpty) return false;

  final data = result.first;

 usuarioActual = Usuario(
  id: data['id']?.toString() ?? '',
  nombre: data['nombre']?.toString() ?? '',
  email: data['email']?.toString() ?? '',
  rol: data['rol']?.toString() ?? '',
  foto: data['foto']?.toString(),
);
  notifyListeners();

  return true;
}

  void logout() {
    usuarioActual = null;
    notifyListeners();
  }

 Future agregarMascota(Mascota mascota) async {

  final db = await DBHelper.database;

  await db.insert('mascotas', {
    'id': mascota.id,
    'nombre': mascota.nombre,
    'especie': mascota.especie,
    'raza': mascota.raza,
    'edad': mascota.edad,
    'peso': mascota.peso,
    'sexo': mascota.sexo,
    'color': mascota.color,
    'usuarioId': usuarioActual!.id
  });

  mascotas.add(mascota);
  notifyListeners();
}

 Future agregarCita(Cita cita) async {

  final db = await DBHelper.database;

  await db.insert('citas', {
    'id': cita.id,
    'clienteId': cita.clienteId,
    'mascotaId': cita.mascotaId,
    'fecha': cita.fecha.toIso8601String(),
    'veterinario': cita.veterinario,
    'servicio': cita.servicio,
    'estado': cita.estado
  });

  citas.add(cita);
  notifyListeners();
}

  List<Cita> obtenerCitasUsuario(String clienteId) {
    return citas.where((c) => c.clienteId == clienteId).toList();
  }


void actualizarPerfil(String nombre, String email, String? foto) {
  if (usuarioActual != null) {
    usuarioActual!.nombre = nombre;
    usuarioActual!.email = email;
    usuarioActual!.foto = foto ?? usuarioActual!.foto;
    notifyListeners();
  }
}
}

/// ---------------- LOGIN ----------------
class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController conController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: width * 0.1),
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 300,
                      height: 200,
                    ),
                    SizedBox(height: 12),
                    Text('Bienvenido',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:const Color.fromARGB(255, 0, 50, 92))),
                         TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        )),
                    SizedBox(height: 20),
                    TextField(
                        controller: conController,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        )),
                    SizedBox(height: 10),
                   
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blue, 
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Registrar'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RegisterScreen()),
                        );
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text('Iniciar Sesión'),
                      onPressed: () async {
                        if (await app.login(emailController.text)) {
                          Navigator.pushReplacement(context,MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Usuario no encontrado')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// ---------------- REGISTER ----------------
class RegisterScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController contraController = TextEditingController();
  final TextEditingController nacController = TextEditingController();
  final TextEditingController genContorller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: width * 0.1),
            elevation: 12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      width: 300,
                      height: 200,
                    ),
                    SizedBox(height: 12),
                    Text('Bienvenido',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color:const Color.fromARGB(255, 0, 50, 92))),
                    SizedBox(height: 20),
                    TextField(
                        controller: nombreController,
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        )),
                    SizedBox(height: 10),
                    TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        )),
                      SizedBox(height: 10),

                    TextField(
                      controller: contraController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      controller: nacController,
                      decoration: InputDecoration(
                        labelText: 'Fecha de nacimiento',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.cake),
                      ),
                    ),

                    SizedBox(height: 10),

                    TextField(
                      controller: genContorller,
                      decoration: InputDecoration(
                        labelText: 'Género',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),

                    SizedBox(height: 20),
                    SizedBox(height: 20),
                    SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: Colors.blue,
                      ),
                      child: Text(
                        'Registrar',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        if (nombreController.text.isEmpty ||
                            emailController.text.isEmpty ||
                            contraController.text.isEmpty ||
                            nacController.text.isEmpty ||
                            genContorller.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Completa todos los campos')),
                          );
                          return;
                        }

                        final nuevoUsuario = Usuario(
                          id: DateTime.now().toString(),
                          nombre: nombreController.text,
                          email: emailController.text,
                        );

                        app.registrarUsuario(nuevoUsuario);
                        app.usuarioActual = nuevoUsuario;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
/// ---------------- DASHBOARD ----------------
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola ${app.usuarioActual?.nombre ?? ''}'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              app.logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _menuButton(
                context,
                'Mis Citas',
                Icons.calendar_today,
                HomeScreen(), 
              ),
              SizedBox(height: 20),
              _menuButton(
                context,
                'Registrar Mascota',
                Icons.pets,
                HomeScreen(),
              ),
              SizedBox(height: 20),
              _menuButton(
                context,
                'Registrar Cita',
                Icons.medical_services,
                HomeScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
      BuildContext context, String text, IconData icon, Widget screen) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 28),
      label: Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text(text, style: TextStyle(fontSize: 18)),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 60),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
    );
  }
}

/// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final TextEditingController mascotaController = TextEditingController();
  final TextEditingController veterinarioController = TextEditingController();
  final TextEditingController servicioController = TextEditingController();
  final TextEditingController fechaController = TextEditingController();
  final TextEditingController razaController = TextEditingController();
  final TextEditingController edadController = TextEditingController();
  final TextEditingController pesoController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  File? imagenMascota;
  final ImagePicker picker = ImagePicker();
  final TextEditingController nombrePerfilController = TextEditingController();
final TextEditingController emailPerfilController = TextEditingController();
File? imagenPerfil;

  Future seleccionarImagen() async {
  final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

  if (imagen != null) {
    setState(() {
      imagenMascota = File(imagen.path);
    });
  }
}


String especieSeleccionada = 'Perro';
String sexoSeleccionado = 'Macho';

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola ${app.usuarioActual?.nombre ?? ''}'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              app.logout();
              Navigator.pop(context);
            },
          )
        ],
      ),

      body: _selectedIndex == 0
          ? _inicio(app)
          : _selectedIndex == 1
              ? _citas(app)
              : _selectedIndex == 2
                  ? _mascotas(app)
                  : _perfil(app),


      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 8,
        child: Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(Icons.home,
                    color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 0),
              ),
              IconButton(
                icon: Icon(Icons.calendar_today,
                    color: _selectedIndex == 1 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 1),
              ),
              SizedBox(width: 40),
              IconButton(
                icon: Icon(Icons.pets,
                    color: _selectedIndex == 2 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 2),
              ),
              IconButton(
                icon: Icon(Icons.person,
                    color: _selectedIndex == 3 ? Colors.blue : Colors.grey),
                onPressed: () => setState(() => _selectedIndex = 3),
              ),
            ],
          ),
        ),
      ),
      
    );
  }
  Future seleccionarFotoPerfil() async {
  final XFile? imagen = await picker.pickImage(source: ImageSource.gallery);

  if (imagen != null) {
    setState(() {
      imagenPerfil = File(imagen.path);
    });
  }
}

  // ---------------- PANTALLA INICIO ----------------
  Widget _inicio(AppProvider app) {
  final citas = app.obtenerCitasUsuario(app.usuarioActual!.id);

  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // 🐶 Imagen principal
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/cd.png",
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        SizedBox(height: 20),

        // Citas pendientes 
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Citas Pendientes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Ver todo",
              style: TextStyle(color: Colors.blue),
            )
          ],
        ),

        SizedBox(height: 10),

        citas.isEmpty
            ? Text("No tienes citas registradas")
            : SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: citas.length,
                  itemBuilder: (context, index) {
                    final cita = citas[index];
                    return Container(
                      width: 200,
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cita.servicio,
                            style: TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 5),
                          Text("Vet: ${cita.veterinario}"),
                          SizedBox(height: 5),
                          Text(
                            "${cita.fecha.toLocal()}".split(' ')[0],
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

        SizedBox(height: 25),

        // 🐾 Mascotas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Mascotas",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Ver todo",
              style: TextStyle(color: Colors.blue),
            )
          ],
        ),

        SizedBox(height: 10),

        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: app.mascotas.length,
            itemBuilder: (context, index) {
              final mascota = app.mascotas[index];
              return Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 12),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.pets, color: Colors.blue),
                  ),
                  SizedBox(height: 5),
                  Text(mascota.nombre),
                ],
              );
            },
          ),
        ),

        SizedBox(height: 25),

        // 👩‍⚕️ Veterinarios

        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset("assets/vet.jpg",
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    ),
  );
}

  // ---------------- PANTALLA CITAS ----------------
Widget _citas(AppProvider app) {
  DateTime fechaSeleccionada = DateTime.now();
  String horaSeleccionada = "";
  String? motivoSeleccionado;
  String? veterinarioSeleccionado;

  final List<String> horarios = [
    "09:00 AM",
    "09:30 AM",
    "10:00 AM",
    "10:30 AM",
    "11:00 AM",
    "11:30 AM",
    "03:00 PM",
    "03:30 PM",
    "04:00 PM",
    "04:30 PM",
  ];

  final List<String> motivos = [
    "Consulta General",
    "Vacunación",
    "Desparasitación",
    "Cirugía",
    "Emergencia",
    "Baño y Grooming",
  ];

  final List<String> veterinarios = [
    "Dr. Carlos Ramírez",
    "Dra. Sofía Mendoza",
    "Dr. Andrés López",
    "Dra. Valeria Torres",
  ];

  return StatefulBuilder(
    builder: (context, setState) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text(
              "Agendar Cita",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// 🔹 MOTIVO
            DropdownButtonFormField<String>(
              value: motivoSeleccionado,
              decoration: InputDecoration(
                labelText: "Motivo de la cita",
                prefixIcon: const Icon(Icons.pets),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: motivos
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(m),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  motivoSeleccionado = value;
                });
              },
            ),

            const SizedBox(height: 15),

            /// 🔹 VETERINARIO
            DropdownButtonFormField<String>(
              value: veterinarioSeleccionado,
              decoration: InputDecoration(
                labelText: "Seleccionar Veterinario",
                prefixIcon: const Icon(Icons.medical_services),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              items: veterinarios
                  .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  veterinarioSeleccionado = value;
                });
              },
            ),

            const SizedBox(height: 20),

            const Text(
              "Seleccionar Fecha",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(10),
              child: CalendarDatePicker(
                initialDate: fechaSeleccionada,
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                onDateChanged: (date) {
                  setState(() {
                    fechaSeleccionada = date;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Seleccionar Horario",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: horarios.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                final hora = horarios[index];
                final seleccionada = hora == horaSeleccionada;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      horaSeleccionada = hora;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: seleccionada
                          ? const Color(0xFF00B2FB)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hora,
                      style: TextStyle(
                        color:
                            seleccionada ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B2FB),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: (motivoSeleccionado == null ||
                        veterinarioSeleccionado == null ||
                        horaSeleccionada.isEmpty)
                    ? null
                    : () {
                        app.agregarCita(Cita(
                          id: DateTime.now().toString(),
                          clienteId: app.usuarioActual!.id,
                          mascotaId: app.mascotas.isNotEmpty
                              ? app.mascotas.last.id
                              : '',
                          fecha: fechaSeleccionada,
                          veterinario: veterinarioSeleccionado!,
                          servicio: motivoSeleccionado!,
                        ));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Cita agendada correctamente"),
                          ),
                        );
                      },
                child: const Text(
                  "Confirmar Cita",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
  // ---------------- PANTALLA MASCOTAS ----------------
  Widget _mascotas(AppProvider app) {
  return SingleChildScrollView(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Center(
          child: GestureDetector(
            onTap: seleccionarImagen,
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  imagenMascota != null ? FileImage(imagenMascota!) : null,
              child: imagenMascota == null
                  ? Icon(Icons.camera_alt, size: 30, color: Colors.grey)
                  : null,
            ),
          ),
        ),

        SizedBox(height: 10),

        Center(
          child: Text(
            "Agregar foto de la mascota",
            style: TextStyle(color: Colors.grey),
          ),
        ),

        SizedBox(height: 25),

        Text(
          "Registrar Mascota",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 15),

        TextField(
          controller: mascotaController,
          decoration: InputDecoration(
            labelText: 'Nombre de la mascota',
            prefixIcon: Icon(Icons.pets),
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: razaController,
          decoration: InputDecoration(
            labelText: 'Raza',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: edadController,
          decoration: InputDecoration(
            labelText: 'Edad',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: pesoController,
          decoration: InputDecoration(
            labelText: 'Peso',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        TextField(
          controller: colorController,
          decoration: InputDecoration(
            labelText: 'Color',
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 20),

        ElevatedButton(
          child: Text("Registrar Mascota"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
            foregroundColor: Colors.white,
          ),
          onPressed: () {

            if (mascotaController.text.isEmpty) return;

            app.agregarMascota(
              Mascota(
                id: DateTime.now().toString(),
                nombre: mascotaController.text,
                especie: "Perro",
                raza: razaController.text,
                edad: edadController.text,
                peso: pesoController.text,
                sexo: "Macho",
                color: colorController.text,
              ),
            );

            mascotaController.clear();
            razaController.clear();
            edadController.clear();
            pesoController.clear();
            colorController.clear();

            setState(() {
              imagenMascota = null;
            });
          },
        ),

        SizedBox(height: 30),

        Text(
          "Mascotas registradas",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 10),

        ...app.mascotas.map((m) => Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.pets, color: Colors.white),
                ),
                title: Text(m.nombre),
                subtitle: Text(
                  "Raza: ${m.raza} | Edad: ${m.edad} | Peso: ${m.peso} kg",
                ),
              ),
            )),
      ],
    ),
  );
}

// ---------------- PANTALLA PERFIL ----------------
Widget _perfil(AppProvider app) {

  final usuario = app.usuarioActual;

  nombrePerfilController.text = usuario?.nombre ?? "";
  emailPerfilController.text = usuario?.email ?? "";

  return SingleChildScrollView(
    padding: EdgeInsets.all(20),
    child: Column(
      children: [

        // FOTO DE PERFIL
        GestureDetector(
          onTap: seleccionarFotoPerfil,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: imagenPerfil != null
                ? FileImage(imagenPerfil!)
                : (usuario?.foto != null
                    ? FileImage(File(usuario!.foto!))
                    : null),
            child: (imagenPerfil == null && usuario?.foto == null)
                ? Icon(Icons.camera_alt, size: 40)
                : null,
          ),
        ),

        SizedBox(height: 10),

        // NOMBRE
        Text(
          usuario?.nombre ?? "Usuario",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 5),

        // EMAIL
        Text(
          usuario?.email ?? "",
          style: TextStyle(
            color: Colors.grey,
          ),
        ),

        SizedBox(height: 30),

        // EDITAR NOMBRE
        TextField(
          controller: nombrePerfilController,
          decoration: InputDecoration(
            labelText: "Editar nombre",
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 10),

        // EDITAR EMAIL
        TextField(
          controller: emailPerfilController,
          decoration: InputDecoration(
            labelText: "Editar email",
            border: OutlineInputBorder(),
          ),
        ),

        SizedBox(height: 20),

        // GUARDAR CAMBIOS
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
            foregroundColor: Colors.white,
          ),
          onPressed: () {

            app.actualizarPerfil(
              nombrePerfilController.text,
              emailPerfilController.text,
              imagenPerfil?.path,
            );

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Perfil actualizado")),
            );
          },
          child: Text("Guardar cambios"),
        ),

        SizedBox(height: 20),

        // CERRAR SESIÓN
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            minimumSize: Size(double.infinity, 50),
            foregroundColor: Colors.white,
          ),
          onPressed: () {

            app.logout();

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
            );

          },
          child: Text("Cerrar sesión"),
        ),
      ],
    ),
  );
}

}
/// ---------------- APP PRINCIPAL ----------------
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Clínica Veterinaria',
        theme: ThemeData(primarySwatch: Colors.blue),
        home: LoginScreen(),
      ),
    ),
  );
}

