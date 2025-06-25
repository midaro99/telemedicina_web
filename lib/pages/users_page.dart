import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:telemedicina_web/models/user.dart';
import 'package:telemedicina_web/config/env.dart';

const Color primaryBlue = Color(0xFF002856);
const Color dangerRed   = Color(0xFFA51008);

class UsersPage extends StatefulWidget {
  const UsersPage({Key? key}) : super(key: key);

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final String _baseApi = '${AppConfig.baseUrl}/api';

  late Future<List<User>> _futureUsers;

  final _nombreCtrl          = TextEditingController();
  final _usuarioCtrl         = TextEditingController();
  final _correoCtrl          = TextEditingController();
  final _especializacionCtrl = TextEditingController();
  final _passCtrl            = TextEditingController();
  final _nRegistroCtrl       = TextEditingController();
  final _formKey             = GlobalKey<FormState>();

  String  _rol        = 'ADMIN';
  bool    _isEdit     = false;
  String? _editingId;
  String? _sexo;
  final   List<String> _sexos = ['MASCULINO', 'FEMENINO', 'OTRO'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() {
    setState(() {
      _futureUsers = _fetchUsers();
    });
  }

  Future<List<User>> _fetchUsers() async {
    final adminsResp = await http.get(Uri.parse('$_baseApi/users'));
    final docsResp   = await http.get(Uri.parse('$_baseApi/medicos'));
    if (adminsResp.statusCode == 200 && docsResp.statusCode == 200) {
      final admins = (jsonDecode(utf8.decode(adminsResp.bodyBytes)) as List)
          .map((j) => User.fromJson({...j, 'role': 'ADMIN'}))
          .toList();
      final docs = (jsonDecode(utf8.decode(docsResp.bodyBytes)) as List)
          .map((j) => User.fromJson({...j, 'role': 'DOCTOR'}))
          .toList();
      return [...admins, ...docs];
    }
    throw Exception('Error al cargar usuarios y médicos');
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) return;
    final body = <String, dynamic>{
      'usuario'   : _usuarioCtrl.text.trim(),
      'contrasena': _passCtrl.text.trim(),
      'nombre'    : _nombreCtrl.text.trim(),
      if (_rol=='DOCTOR') 'correo'        : _correoCtrl.text.trim(),
      if (_rol=='DOCTOR') 'especializacion': _especializacionCtrl.text.trim(),
      if (_rol=='DOCTOR') 'sexo'          : _sexo!,
      if (_rol=='DOCTOR') 'n_registro'    : _nRegistroCtrl.text.trim(),
    };
    final endpoint = _rol == 'ADMIN' ? 'users' : 'medicos';
    late http.Response resp;
    if (_isEdit && _editingId != null) {
      resp = await http.put(
        Uri.parse('$_baseApi/$endpoint/$_editingId'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode(body),
      );
    } else {
      resp = await http.post(
        Uri.parse('$_baseApi/$endpoint'),
        headers: {'Content-Type':'application/json'},
        body: jsonEncode(body),
      );
    }
    if (resp.statusCode == (_isEdit ? 200 : 201)) {
  print('✅ Usuario guardado correctamente');
  print('Respuesta: ${resp.body}');
  Navigator.pop(context);
  _loadUsers();
} else {
  print('❌ Error al guardar usuario');
  print('Código de estado: ${resp.statusCode}');
  print('Respuesta: ${resp.body}');
  print('Payload enviado: ${jsonEncode(body)}');
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error ${resp.statusCode} al guardar')),
  );
}
  }



  Future<void> _deleteUser(String role, String id) async {
    final endpoint = role=='ADMIN' ? 'users' : 'medicos';
    final resp = await http.delete(Uri.parse('$_baseApi/$endpoint/$id'));
    if (resp.statusCode == 204) {
      _loadUsers();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ${resp.statusCode} al eliminar')),
      );
    }
  }

  void _showDeleteDialog(User u) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(12)
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // header
            Container(
              decoration: BoxDecoration(
                color: primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding: EdgeInsets.symmetric(horizontal:16, vertical:12),
              child: Row(
                children:[
                  Expanded(child: Text(
                    'Confirmar eliminación',
                    style: TextStyle(color:Colors.white, fontWeight:FontWeight.bold)
                  )),
                  GestureDetector(
                    onTap: ()=>Navigator.pop(context),
                    child: Container(
                      width:32, height:32,
                      decoration: BoxDecoration(color:dangerRed, shape:BoxShape.circle),
                      child: Icon(Icons.close, color:Colors.white, size:20),
                    ),
                  )
                ]
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Text('¿Eliminar a ${u.nombre}?'),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal:16, vertical:12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children:[
                  TextButton(
                    onPressed: ()=>Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: dangerRed),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width:8),
                  ElevatedButton(
                    onPressed: (){
                      Navigator.pop(context);
                      _deleteUser(u.role,u.publicId);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerRed, foregroundColor: Colors.white
                    ),
                    child: Text('Eliminar'),
                  ),
                ],
              )
            )
          ]),
        ),
      ),
    );
  }

  void _showUserDialog([User? u]) {
    // prefill si es edición
    if (u != null) {
      _isEdit        = true;
      _editingId     = u.publicId;
      _rol           = u.role;
      _nombreCtrl.text          = u.nombre;
      _usuarioCtrl.text         = u.usuario;
      _correoCtrl.text          = u.correo;
      _especializacionCtrl.text = u.especializacion ?? '';
      _passCtrl.clear();
      _sexo = u.sexo;
      _nRegistroCtrl.text = u.nRegistro ?? '';
    } else {
      _isEdit = false;
      _editingId = null;
      _rol = 'ADMIN';
      _nombreCtrl.clear();
      _usuarioCtrl.clear();
      _correoCtrl.clear();
      _especializacionCtrl.clear();
      _passCtrl.clear();
      _sexo = null;
      _nRegistroCtrl.clear();
    }

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctxDialog, setStateDialog) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal:24),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children:[
              // header
              Container(
                decoration: BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                padding: EdgeInsets.symmetric(horizontal:16, vertical:12),
                child: Row(
                  children:[
                    Expanded(child: Text(
                      _isEdit
                        ? 'Editar ${_rol=="ADMIN"?"Administrador":"Médico"}'
                        : 'Crear ${_rol=="ADMIN"?"Administrador":"Médico"}',
                      style: TextStyle(color:Colors.white, fontWeight:FontWeight.bold)
                    )),
                    GestureDetector(
                      onTap: ()=>Navigator.pop(context),
                      child: Container(
                        width:32, height:32,
                        decoration: BoxDecoration(color:dangerRed, shape:BoxShape.circle),
                        child: Icon(Icons.close, color:Colors.white, size:20),
                      ),
                    )
                  ]
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(mainAxisSize: MainAxisSize.min, children:[
                    // DROPDOWN ROL con fondo blanco
                    DropdownButtonFormField<String>(
                      value: _rol,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(value: 'ADMIN',  child: Text('Administrador')),
                        DropdownMenuItem(value: 'DOCTOR', child: Text('Médico')),
                      ],
                      onChanged: (v) => setStateDialog(() {
                        _rol = v!;
                        if (_rol != 'DOCTOR') {
                          _sexo = null;
                          _nRegistroCtrl.clear();
                          _correoCtrl.clear();
                          _especializacionCtrl.clear();
                        }
                      }),
                    ),

                    SizedBox(height:8),
                    TextFormField(
                      controller: _nombreCtrl,
                      decoration: InputDecoration(labelText:'Nombre'),
                      validator:(val){
                        if(val==null||val.trim().isEmpty) return 'Obligatorio';
                        if(val.trim().length<4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                    ),
                    SizedBox(height:8),
                    TextFormField(
                      controller: _usuarioCtrl,
                      decoration: InputDecoration(labelText:'Usuario'),
                      validator:(val){
                        if(val==null||val.trim().isEmpty) return 'Obligatorio';
                        if(val.trim().length<4) return 'Mínimo 4 caracteres';
                        return null;
                      },
                    ),

                    // Campos extra SOLO si es DOCTOR
                    if (_rol == 'DOCTOR') ...[
                      SizedBox(height:8),
                      TextFormField(
                        controller: _correoCtrl,
                        decoration: InputDecoration(labelText:'Correo'),
                        validator:(val){
                          if(val==null||val.trim().isEmpty) return 'Obligatorio';
                          final re=RegExp(r'^[^@]+@[^@]+\.[^@]+');
                          if(!re.hasMatch(val.trim())) return 'Email inválido';
                          return null;
                        },
                      ),
                      SizedBox(height:8),
                      TextFormField(
                        controller:_especializacionCtrl,
                        decoration:InputDecoration(labelText:'Especialización'),
                        validator:(val)=>val==null||val.trim().isEmpty?'Obligatorio':null,
                      ),
                      SizedBox(height:8),
                      // DROPDOWN SEXO con fondo blanco
                      DropdownButtonFormField<String>(
                        value: _sexo,
                        dropdownColor: Colors.white,
                        decoration: InputDecoration(labelText:'Sexo'),
                        items: _sexos.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s[0] + s.substring(1).toLowerCase())
                        )).toList(),
                        onChanged: (v) => setStateDialog(() => _sexo = v),
                        validator:(val)=>val==null||val.isEmpty?'Obligatorio':null,
                      ),
                      SizedBox(height:8),
                      TextFormField(
                        controller:_nRegistroCtrl,
                        decoration:InputDecoration(labelText:'N° Registro'),
                        validator:(val){
                          if(val==null||val.trim().isEmpty) return 'Obligatorio';
                          if(val.trim().length<3) return 'Mínimo 3 caracteres';
                          return null;
                        },
                      ),
                    ],

                    SizedBox(height:8),
                    TextFormField(
                      controller: _passCtrl,
                      decoration: InputDecoration(labelText: _isEdit ? 'Contraseña (nueva)' : 'Contraseña'),
                      obscureText: true,
                      validator:(val){
                        if(!_isEdit){
                          if(val==null||val.trim().isEmpty) return 'Obligatorio';
                          if(val.trim().length<6) return 'Mínimo 6 caracteres';
                        } else if(val!=null&&val.isNotEmpty&&val.trim().length<6){
                          return 'Mínimo 6 caracteres';
                        }
                        return null;
                      },
                    ),
                  ]),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal:16, vertical:12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children:[
                  TextButton(
                    onPressed: ()=>Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: dangerRed),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width:8),
                  ElevatedButton(
                    onPressed: _saveUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerRed, foregroundColor:Colors.white
                    ),
                    child: Text('Guardar'),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left:16),
          child: GestureDetector(
            onTap: ()=>Navigator.pop(context),
            child: Container(
              width:36, height:36,
              decoration: BoxDecoration(color:dangerRed, shape:BoxShape.circle),
              child: Icon(Icons.arrow_back, color:Colors.white, size:20),
            ),
          ),
        ),
        title: Row(
          children: [
            Image.asset('assets/images/logoucuencaprincipal.png', height:32),
            SizedBox(width:8),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right:16),
            child: Center(child: Text(
              'Gestionar Usuarios / Médicos',
              style: TextStyle(color:Colors.white),
            )),
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: _futureUsers,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final list = snap.data!;
          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical:8),
            itemCount: list.length,
            itemBuilder: (ctx,i){
              final u = list[i];
              return ListTile(
                leading: Icon(
                  u.role=='ADMIN'
                    ? Icons.admin_panel_settings
                    : Icons.medical_services,
                  color: Colors.black54
                ),
                title: Text(u.nombre),
                subtitle: Text('${u.usuario} · ${u.role}'),
                trailing: Row(mainAxisSize: MainAxisSize.min, children:[
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.black87),
                    onPressed: ()=>_showUserDialog(u),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.black87),
                    onPressed: ()=>_showDeleteDialog(u),
                  ),
                ]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: dangerRed,
        foregroundColor: Colors.white,
        onPressed: ()=>_showUserDialog(),
        child: Icon(Icons.add),
      ),
    );
  }
 
  @override
  void dispose() {
    _nombreCtrl.dispose();
    _usuarioCtrl.dispose();
    _correoCtrl.dispose();
    _especializacionCtrl.dispose();
    _passCtrl.dispose();
    _nRegistroCtrl.dispose();
    super.dispose();
  }
}
