import 'package:csv/csv.dart';
import '../models/csv_data.dart';

enum CsvParseErrorType {
  emptyCsv,
  invalidHeaderCount,
  noDataRows,
  parseFailed,
}

class CsvParseException implements Exception {
  final CsvParseErrorType type;
  final Object? cause;

  CsvParseException(this.type, {this.cause});

  @override
  String toString() => 'CsvParseException($type)';
}

class CsvService {
  // Parser un fichier CSV depuis son contenu texte
  Future<List<CsvData>> parseCsv(String csvContent) async {
    try {
      // Convertir le CSV en liste de listes avec des règles de parsing
      final List<List<dynamic>> rows = const CsvToListConverter(
        fieldDelimiter: ',', // Délimiteur de champs (virgule par défaut)
        textDelimiter: '"', // Délimiteur de texte (guillemets)
        textEndDelimiter: '"', // Fin du délimiteur de texte
        eol: '\n', // Fin de ligne
        shouldParseNumbers: true, // Convertir automatiquement les nombres
        allowInvalid: false, // Rejeter les CSV invalides
      ).convert(csvContent.replaceAll('\r\n', '\n'));

      if (rows.isEmpty) {
        throw CsvParseException(CsvParseErrorType.emptyCsv);
      }

      // La première ligne contient les en-têtes
      final List<String> headers = rows.first
          .map((dynamic e) => e.toString())
          .toList();
      if (headers.length != 14) {
        throw CsvParseException(CsvParseErrorType.invalidHeaderCount);
      }

      // Les autres lignes contiennent les données
      final List<List<dynamic>> dataRows = rows.skip(1).toList();

      if (dataRows.isEmpty) {
        throw CsvParseException(CsvParseErrorType.noDataRows);
      }

      // Parser toutes les lignes en une seule fois
      final CsvData csvData = CsvData.fromCsv(headers, dataRows);

      return <CsvData>[csvData];
    } catch (e) {
      if (e is CsvParseException) {
        rethrow;
      }
      throw CsvParseException(CsvParseErrorType.parseFailed, cause: e);
    }
  }

  // Valider le format du CSV basé sur les workouts
  bool validateCsvFormat(List<CsvData> data) {
    if (data.isEmpty) return false;

    final CsvData csvData = data.first;

    // Vérifier qu'il y a au moins un workout
    if (csvData.workouts.isEmpty) return false;

    // Vérifier que chaque workout a des exercices
    for (final workout in csvData.workouts) {
      if (workout.exercises.isEmpty) return false;

      // Vérifier que chaque exercice a des sets
      for (final exercise in workout.exercises) {
        if (exercise.sets.isEmpty) return false;
      }
    }

    return true;
  }
}
