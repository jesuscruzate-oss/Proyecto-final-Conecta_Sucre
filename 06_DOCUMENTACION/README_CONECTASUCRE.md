# ConectaSucre — Database Project (parcial corte 2)

Implementación académica de la gestión de pedidos, transporte, seguimiento de entregas, novedades NoSQL, búsqueda semántica y migración del núcleo relacional de MySQL a PostgreSQL.

## Componentes y alcance
- `scripts_sql/`: scripts 01 a 10 para MySQL. Ejecutar secuencialmente en un entorno de prueba siguiendo comentarios de cada archivo.
- `nosql/`: `11_NOSQL_MONGODB.js`, documentos de demostración exportados desde Compass (`novedades_logisticas.json`) y definición del índice Atlas (`idx_incidentes_semanticos.json`). **Importante**: el script 11 usa la colección `novedades_eventos`, diferente de `novedades_logisticas` empleada para búsqueda vectorial; no intercambiar sus datos por error.
- `vectorial/`: notebook de generación de embeddings y script JavaScript de carga/consulta. El índice `idx_incidentes_semanticos` usa `embedding`, dimensión 384 y similitud `cosine`.
- `migracion/`: scripts 13 para PostgreSQL y backup opcional `.backup`. El respaldo se restauró en una base independiente durante las pruebas.
- `documentacion/`: informe técnico editable Word y versión de entrega PDF.
- `evidencias/`: capturas originales seleccionadas.

## Dependencias
MySQL Workbench / servidor MySQL, MongoDB Atlas y Compass, PostgreSQL 17 con pgAdmin 4. Para el notebook se utiliza Python con la biblioteca de embeddings especificada dentro del cuaderno.

## Despliegue reproducible (ambiente de pruebas)
1. Crear una base MySQL vacía y ejecutar en orden los scripts `01_DDL.sql` a `10_TRIGGERS.sql`. Revisar previamente las instrucciones y privilegios de `05_DCL.sql`.
2. En MongoDB Atlas, crear una cuenta y un clúster de práctica. Autorizar solamente las IP necesarias en Network Access; no publicar cadenas de conexión. Ejecutar el script NoSQL en mongosh para la colección `novedades_eventos` y/o importar el JSON exportado a `novedades_logisticas`, según la prueba deseada.
3. Crear un índice Atlas Vector Search con la configuración `idx_incidentes_semanticos.json` en `conectasucre_nosql.novedades_logisticas`. Asegurar que las dimensiones de los embeddings de consulta coincidan con las almacenadas.
4. En PostgreSQL 17, **opción preferida**: crear una base vacía de prueba y restaurar el archivo CUSTOM usando `pg_restore` o pgAdmin. **Alternativa**: crear una base vacía, ejecutar scripts 13_01, 13_03, 13_04, 13_05, 13_06 y 13_07 en ese orden. Evitar ejecutar ambas opciones sobre la misma base poblada.
5. Verificar en PostgreSQL que existan 15 tablas, 10 vistas y 20 claves foráneas; los pedidos y despachos de la muestra original tenían 200 registros cada uno.

## Seguridad
- No subir archivos `.env`, claves de Atlas, contraseñas o credenciales personales.
- `README.md` no debe contener contraseñas: usar variables de entorno y transmitir accesos de prueba por canal privado.
- Se recomienda repositorio **privado** y revisión de SQL dumps antes de publicar, pues pueden contener datos internos o usuarios.
- Si una contraseña fue expuesta durante el desarrollo, rotarla antes de compartir el repositorio.

## Resultados documentados
15 tablas, 1.350 filas migradas, 20 claves foráneas, 10 vistas, 6 funciones ordinarias, 4 procedimientos y 5 triggers en PostgreSQL. El backup se leyó con `pg_restore --list` y se probó su restauración en una base independiente.

## Informe y evidencia
La guía solicita informe técnico **en PDF**. El DOCX es un editable auxiliar. Para la evaluación utilizar `documentacion/ConectaSucre_Informe_Tecnico_Definitivo.pdf` y los scripts entregados.

## Limitaciones
Este repositorio documenta un prototipo de bases de datos, **no** una plataforma comercial web terminada ni un despliegue productivo multiusuario. No se midió rendimiento a escala ni precisión estadística de búsqueda semántica.
