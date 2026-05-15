import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import 'dart:io';
import 'dart:convert';

class ApiService {
  ApiService();

  static const String _userKey = 'current_user';
  static const String _balanceKey = 'user_balance';
  static const String _transfersKey = 'user_transfers';
  static const String _profileKey = 'user_profile';
  static const String _passwordKey = 'user_password';

  String? _currentUser;
  
  // Getter para usuário atual
  String? get usuarioAtual => _currentUser;

  // Login com CPF e senha
  Future<bool> login(String identificador, String senha) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUser = prefs.getString(_userKey);
      final storedPassword = prefs.getString(_passwordKey);
      
      if (storedUser == identificador && storedPassword == senha) {
        _currentUser = identificador;
        return true;
      }
      
      // Primeiro login - cria conta com dados iniciais
      await prefs.setString(_userKey, identificador);
      await prefs.setString(_passwordKey, senha);
      await prefs.setDouble(_balanceKey, 30000.0);
      _currentUser = identificador;
      return true;
    } catch (e) {
      throw Exception('Erro ao fazer login: ${e.toString()}');
    }
  }

  // Registro
  Future<bool> register(String identificador, String senha, {
    required String nome, 
    required String cpf, 
    required String telefone
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verifica se já existe
      if (prefs.getString(_userKey) == identificador) {
        throw Exception('Usuário já cadastrado');
      }

      // Salva dados do usuário
      await prefs.setString(_userKey, identificador);
      await prefs.setString(_passwordKey, senha);
      await prefs.setDouble(_balanceKey, 30000.0);
      
      // Salva perfil
      final profile = {
        'nome': nome,
        'cpf': cpf,
        'telefone': telefone,
        'email': identificador.contains('@') ? identificador : '$identificador@northbank.com',
      };
      await prefs.setString(_profileKey, jsonEncode(profile));
      
      _currentUser = identificador;
      return true;
    } catch (e) {
      throw Exception('Erro ao registrar: ${e.toString()}');
    }
  }

  bool get isLoggedIn => _currentUser != null;

  void logout() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUser = null;
    await prefs.remove(_userKey);
    await prefs.remove(_passwordKey);
  }

  Future<Map<String, double>> fetchCotacoes() async {
    return {
      'dolar': 4.95,
      'euro': 5.35,
    };
  }

  Future<double> fetchSaldo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_balanceKey) ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> fetchHistorico() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historico = prefs.getStringList(_transfersKey) ?? [];
      return historico.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadProfilePhoto(File file, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo_$userId', file.path);
    return file.path;
  }

  Future<void> updateProfilePhotoUrl(String userId, String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_photo_url_$userId', url);
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(_profileKey);
    if (profileStr != null) {
      return jsonDecode(profileStr) as Map<String, dynamic>;
    }
    return null;
  }

  Future<void> updateUserProfile({
    required String userId, 
    String? nome, 
    String? telefone, 
    String? foto
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profileStr = prefs.getString(_profileKey);
    final profile = profileStr != null 
      ? jsonDecode(profileStr) as Map<String, dynamic>
      : <String, dynamic>{};
    
    if (nome != null) profile['nome'] = nome;
    if (telefone != null) profile['telefone'] = telefone;
    if (foto != null) profile['foto'] = foto;
    
    await prefs.setString(_profileKey, jsonEncode(profile));
  }

  Future<void> registrarTransferencia(
    String destinatario, 
    double valor, {
    String? moeda, 
    double? valorOriginal
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Atualiza saldo
    final saldoAtual = await fetchSaldo();
    if (saldoAtual < valor) {
      throw Exception('Saldo insuficiente');
    }
    await prefs.setDouble(_balanceKey, saldoAtual - valor);
    
    // Registra transferência
    final transferencia = {
      'destinatario': destinatario,
      'valor': valor,
      'moeda': moeda,
      'valor_original': valorOriginal,
      'data': DateTime.now().toString(),
    };
    
    final historico = prefs.getStringList(_transfersKey) ?? [];
    historico.add(jsonEncode(transferencia));
    await prefs.setStringList(_transfersKey, historico);
  }
}