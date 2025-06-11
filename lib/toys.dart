import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Definimos un modelo Toy para representar nuestros datos de juguete
class Toy {
  final String id; // ID del documento de Firestore
  final String idJuguete; // ID específico del juguete (podría ser un SKU, etc.)
  final String nombre;
  final DateTime fechaFabricacion;
  final String marca;
  final double precio;
  final String proveedor;
  final String clasificacion;

  Toy({
    required this.id,
    required this.idJuguete,
    required this.nombre,
    required this.fechaFabricacion,
    required this.marca,
    required this.precio,
    required this.proveedor,
    required this.clasificacion,
  });

  // Constructor de fábrica para crear un objeto Toy desde un DocumentSnapshot de Firestore
  factory Toy.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Toy(
      id: doc.id,
      idJuguete: data['id_juguete'] ?? 'N/A',
      nombre: data['nombre'] ?? 'Sin Nombre',
      fechaFabricacion: (data['fecha_fabricacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      marca: data['marca'] ?? 'Desconocida',
      // Convertimos el precio a double, asegurando un valor por defecto si es nulo o no es un número
      precio: (data['precio'] is num) ? (data['precio'] as num).toDouble() : 0.0,
      proveedor: data['proveedor'] ?? 'Desconocido',
      clasificacion: data['clasificacion'] ?? 'Sin Clasificar',
    );
  }
}

class Toys extends StatefulWidget {
  const Toys({super.key});

  @override
  State<Toys> createState() => _ToysState();
}

class _ToysState extends State<Toys> {
  // Controladores para los campos de texto
  final idJugueteController = TextEditingController();
  final nombreController = TextEditingController();
  final fechaFabricacionController = TextEditingController(); // Para mostrar la fecha seleccionada
  final marcaController = TextEditingController();
  final precioController = TextEditingController();
  final proveedorController = TextEditingController();
  final clasificacionController = TextEditingController();

  // Fecha seleccionada para el campo de fecha de fabricación
  DateTime? selectedDate;

  @override
  void dispose() {
    // Liberar los controladores para evitar fugas de memoria
    idJugueteController.dispose();
    nombreController.dispose();
    fechaFabricacionController.dispose();
    marcaController.dispose();
    precioController.dispose();
    proveedorController.dispose();
    clasificacionController.dispose();
    super.dispose();
  }

  // Función para seleccionar la fecha de fabricación
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.amber, // Color de la cabecera
            colorScheme: const ColorScheme.light(primary: Colors.amber), // Color del selector
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        fechaFabricacionController.text = "${picked.toLocal().day}/${picked.toLocal().month}/${picked.toLocal().year}";
      });
    }
  }


  // Función para agregar un nuevo juguete a Firestore
  Future<void> addToy() async {
    // Validación básica para asegurar que los campos principales no estén vacíos
    if (nombreController.text.trim().isEmpty || marcaController.text.trim().isEmpty || precioController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa el nombre, marca y precio del juguete.')),
      );
      return;
    }

    try {
      // Intentar convertir el precio a double
      final double? parsedPrecio = double.tryParse(precioController.text.trim());
      if (parsedPrecio == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El precio debe ser un número válido.')),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('juguetes').add({
        'id_juguete': idJugueteController.text.trim().isEmpty ? 'N/A' : idJugueteController.text.trim(),
        'nombre': nombreController.text.trim(),
        'fecha_fabricacion': selectedDate != null ? Timestamp.fromDate(selectedDate!) : FieldValue.serverTimestamp(), // Usa la fecha seleccionada o el timestamp del servidor
        'marca': marcaController.text.trim(),
        'precio': parsedPrecio,
        'proveedor': proveedorController.text.trim(),
        'clasificacion': clasificacionController.text.trim(),
        'timestamp_creacion': FieldValue.serverTimestamp(), // Para ordenar y seguimiento
      });

      // Mostrar un mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juguete guardado exitosamente!')),
      );

      // Limpiar los campos de texto después de guardar
      idJugueteController.clear();
      nombreController.clear();
      fechaFabricacionController.clear();
      marcaController.clear();
      precioController.clear();
      proveedorController.clear();
      clasificacionController.clear();
      setState(() {
        selectedDate = null; // Limpiar la fecha seleccionada
      });
      // Ocultar el teclado después de guardar
      FocusScope.of(context).unfocus();
    } catch (e) {
      // Mostrar un mensaje de error si falla el guardado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo al guardar el juguete: $e')),
      );
      print("Error al agregar juguete: $e"); // Registrar el error para depuración
    }
  }

  // Función para eliminar un juguete de Firestore
  Future<void> deleteToy(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('juguetes').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Juguete eliminado exitosamente!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fallo al eliminar el juguete: $e')),
      );
      print("Error al eliminar juguete: $e"); // Registrar el error para depuración
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Juguetes'),
        centerTitle: true,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        // Wrapped the Column with SingleChildScrollView to prevent overflow
        child: Column(
          children: [
            const Text(
              'Mis Juguetes',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
            const SizedBox(height: 20),
            Expanded( // Use Expanded to ensure the scrollable part takes available space
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Campo: ID Juguete
                    TextField(
                      controller: idJugueteController,
                      decoration: InputDecoration(
                        labelText: 'ID Juguete',
                        hintText: 'Ingresa el ID único del juguete',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.05),
                      ),
                      cursorColor: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    // Campo: Nombre
                    TextField(
                      controller: nombreController,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        hintText: 'Nombre del juguete',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.05),
                      ),
                      cursorColor: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    // Campo: Fecha de Fabricación (con selector de fecha)
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: AbsorbPointer(
                        child: TextField(
                          controller: fechaFabricacionController,
                          decoration: InputDecoration(
                            labelText: 'Fecha de Fabricación',
                            hintText: 'Selecciona la fecha de fabricación',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            filled: true,
                            fillColor: Colors.amber.withOpacity(0.05),
                            suffixIcon: const Icon(Icons.calendar_today, color: Colors.amber),
                          ),
                          cursorColor: Colors.amber,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Campo: Marca
                    TextField(
                      controller: marcaController,
                      decoration: InputDecoration(
                        labelText: 'Marca',
                        hintText: 'Marca del juguete',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.05),
                      ),
                      cursorColor: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    // Campo: Precio
                    TextField(
                      controller: precioController,
                      keyboardType: TextInputType.number, // Teclado numérico
                      decoration: InputDecoration(
                        labelText: 'Precio',
                        hintText: 'Precio del juguete',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.05),
                      ),
                      cursorColor: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    // Campo: Proveedor
                    TextField(
                      controller: proveedorController,
                      decoration: InputDecoration(
                        labelText: 'Proveedor',
                        hintText: 'Proveedor del juguete',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.05),
                      ),
                      cursorColor: Colors.amber,
                    ),
                    const SizedBox(height: 20),
                    // Campo: Clasificación
                    TextField(
                      controller: clasificacionController,
                      decoration: InputDecoration(
                        labelText: 'Clasificación',
                        hintText: 'Ej. Educativo, Acción, Peluche',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.amber.withOpacity(0.05),
                      ),
                      cursorColor: Colors.amber,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: addToy, // Llama a la función para agregar juguete
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Guardar Juguete',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            const Divider(color: Colors.amber, thickness: 2),
            const SizedBox(height: 10),
            // Usamos Expanded para que la lista ocupe el espacio restante
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('juguetes') // Colección 'juguetes'
                    .orderBy('timestamp_creacion', descending: true) // Ordenar por fecha de creación
                    .snapshots(),
                builder: (context, snapshot) {
                  // Manejar estado de carga
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  // Manejar estado de error
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                  }

                  // Manejar cuando no hay datos (lista de juguetes vacía)
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No hay juguetes aún! Comienza agregando uno.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  }

                  // Mostrar juguetes
                  final toys = snapshot.data!.docs.map((doc) => Toy.fromFirestore(doc)).toList();

                  return ListView.builder(
                    itemCount: toys.length,
                    itemBuilder: (context, index) {
                      final toy = toys[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16.0),
                          title: Text(
                            toy.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('ID: ${toy.idJuguete}'),
                              Text('Nombre: ${toy.nombre}'),
                              Text('Marca: ${toy.marca}'),
                              Text('Precio: \$${toy.precio.toStringAsFixed(2)}'),
                              Text('Proveedor: ${toy.proveedor}'),
                              Text('Clasificación: ${toy.clasificacion}'),
                              Text('Fabricación: ${toy.fechaFabricacion.toLocal().toString().split(' ')[0]}'),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            onPressed: () => deleteToy(toy.id), // Llama a la función para eliminar juguete
                          ),
                          onTap: () {
                            // Puedes implementar la navegación a una pantalla de detalles/edición aquí
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
