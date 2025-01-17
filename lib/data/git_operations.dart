import 'dart:convert';
import 'dart:io';

import 'package:git_rest/constants.dart';
import 'package:http/http.dart' as http;

class GitOperations {
  final String token;

  GitOperations({required this.token});

  Future<List<dynamic>> listRepositories(bool showPrivateRepos) async {
    final response = await http.get(
      Uri.parse(showPrivateRepos
          ? 'https://api.github.com/user/repos?visibility=all'
          : 'https://api.github.com/user/repos'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load repositories');
    }
  }

  Future<void> createRepository(String repoName, bool isPrivate) async {
    final response = await http.post(
      Uri.parse('https://api.github.com/user/repos'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'name': repoName,
        'private': isPrivate,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create repository');
    }
  }

  Future<void> addFileToRepo(String owner, String repo, String path, File file,
      String commitMessage) async {
    List<int> fileBytes = await file.readAsBytes();
    String base64Content = base64Encode(fileBytes);

    final response = await http.put(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'message': commitMessage,
        'content': base64Content,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add file to repository: ${response.body}');
    }
  }

  Future<dynamic> getRepoContents(
      String owner, String repo, String path) async {
    final response = await http.get(
      Uri.parse('https://api.github.com/repos/$owner/$repo/contents/$path'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get repository contents');
    }
  }

  Future<void> updateFileInRepo(String owner, String repo, String path,
      String newContent, String commitMessage) async {
    final apiUrl = 'https://api.github.com/repos/$owner/$repo/contents/$path';

    // Step 1: Get the current file contents
    final getResponse = await http.get(
      Uri.parse(apiUrl),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (getResponse.statusCode != 200) {
      throw Exception('Failed to get file: ${getResponse.body}');
    }

    final fileInfo = json.decode(getResponse.body);
    final String sha = fileInfo['sha'];

    // Step 2 & 3: Update content and create a commit
    final updateResponse = await http.put(
      Uri.parse(apiUrl),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'message': commitMessage,
        'content': base64Encode(utf8.encode(newContent)),
        'sha': sha,
      }),
    );

    if (updateResponse.statusCode != 200) {
      throw Exception('Failed to update file: ${updateResponse.body}');
    }

    printInDebug('File updated successfully');
  }
}
