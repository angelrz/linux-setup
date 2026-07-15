Option Explicit

' Configuracion principal del libro.
Private Const HOJA_REGISTRAR As String = "Registrar"
Private Const HOJA_EVENTOS As String = "Eventos"

' Columnas de la hoja Eventos.
Private Const COL_EVENTO_ID As String = "A"
Private Const COL_EVENTO_FECHA As String = "B"
Private Const COL_EVENTO_FASE As String = "C"
Private Const COL_EVENTO_COMENTARIO As String = "D"

' Configuracion de PowerPoint.
Private Const ARCHIVO_POWERPOINT_SALIDA As String = "Linea del Tiempo.pptx"
Private Const EVENTOS_POR_DIAPOSITIVA As Long = 6
Private Const DIAPO_PORTADA As Long = 1
Private Const DIAPO_PRIMERA_LINEA As Long = 2
Private Const ETIQUETA_GENERADA As String = "linea_tiempo_generada"

' Medidas tomadas de la plantilla de la linea del tiempo.
Private Const TITULO_X As Single = 54
Private Const TITULO_Y As Single = 28
Private Const TITULO_ANCHO As Single = 852
Private Const TITULO_ALTO As Single = 48
Private Const LINEA_Y As Single = 306
Private Const LINEA_GROSOR As Single = 4
Private Const MARCADOR_DIAMETRO As Single = 16
Private Const CONECTOR_GROSOR As Single = 2
Private Const MAX_CARACTERES_COMENTARIO As Long = 200
Private Const NOMBRE_CANTIDAD_PENDIENTE As String = "CantidadEventosPendientes"
Private Const FECHA_MINIMA_ANIO As Long = 2022
Private Const FECHA_MINIMA_MES As Long = 1
Private Const FECHA_MINIMA_DIA As Long = 1
Private Const FECHA_MAXIMA_ANIO As Long = 2026
Private Const FECHA_MAXIMA_MES As Long = 12
Private Const FECHA_MAXIMA_DIA As Long = 31

Public Sub Auto_Open()
    On Error Resume Next
    AplicarFijacionBotones ThisWorkbook.Worksheets(HOJA_REGISTRAR)
    AplicarValidacionFechaFormulario ThisWorkbook.Worksheets(HOJA_REGISTRAR)
    On Error GoTo 0
End Sub

Public Sub fijarBotonesFormulario()
    AplicarFijacionBotones ThisWorkbook.Worksheets(HOJA_REGISTRAR)
    AplicarValidacionFechaFormulario ThisWorkbook.Worksheets(HOJA_REGISTRAR)
    MsgBox "Los botones quedaron fijos y no cambiaran de tamano con las celdas.", _
        vbInformation, "Botones configurados"
End Sub

Public Sub agregarALineaTiempo()
    Dim wsRegistro As Worksheet
    Dim wsEventos As Worksheet
    Dim fechasEvento() As Date
    Dim fasesEvento() As String
    Dim comentariosEvento() As String
    Dim siguienteFila As Long
    Dim siguienteId As Long
    Dim colFecha As Long
    Dim colFase As Long
    Dim colComentario As Long
    Dim filaEncabezado As Long
    Dim filaCaptura As Long
    Dim cantidad As Long
    Dim textoCantidad As String
    Dim i As Long

    Set wsRegistro = ThisWorkbook.Worksheets(HOJA_REGISTRAR)
    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)

    filaEncabezado = FilaEncabezadoFormulario(wsRegistro)
    If filaEncabezado = 0 Then
        MsgBox "No se encontraron los encabezados Fecha, Fase y Comentario en la hoja Registrar.", vbExclamation, "Formulario incompleto"
        Exit Sub
    End If

    filaCaptura = filaEncabezado + 1
    colFecha = ColumnaPorEncabezado(wsRegistro, "Fecha", filaEncabezado)
    colFase = ColumnaPorEncabezado(wsRegistro, "Fase", filaEncabezado)
    colComentario = ColumnaPorEncabezado(wsRegistro, "Comentario", filaEncabezado)

    AplicarFijacionBotones wsRegistro
    cantidad = CantidadCapturaPendiente()

    If cantidad = 0 Then
        textoCantidad = Trim$(InputBox("Ingresa el numero de eventos que deseas agregar:", "Agregar eventos", "1"))
        If textoCantidad = vbNullString Then Exit Sub
        If Not EsEnteroPositivo(textoCantidad) Then
            MsgBox "La cantidad debe ser un numero entero positivo.", vbExclamation, "Cantidad invalida"
            Exit Sub
        End If

        cantidad = CLng(textoCantidad)
        If cantidad > 50 Then
            MsgBox "Puedes preparar como maximo 50 eventos a la vez.", vbExclamation, "Cantidad demasiado grande"
            Exit Sub
        End If

        PrepararFilasCaptura wsRegistro, filaCaptura, cantidad, colFecha, colFase, colComentario
        GuardarCantidadCaptura cantidad

        If cantidad > 1 Or Not FilaCapturaTieneDatos(wsRegistro, filaCaptura, colFecha, colFase, colComentario) Then
            MsgBox "Se prepararon " & cantidad & " filas." & vbCrLf & vbCrLf & _
                "Captura los eventos y vuelve a pulsar Agregar evento para guardarlos.", _
                vbInformation, "Captura preparada"
            wsRegistro.Cells(filaCaptura, colFecha).Select
            Exit Sub
        End If
    End If

    ReDim fechasEvento(0 To cantidad - 1)
    ReDim fasesEvento(0 To cantidad - 1)
    ReDim comentariosEvento(0 To cantidad - 1)

    ' Valida una sola vez y conserva los datos para no procesar dos veces el lote.
    For i = 0 To cantidad - 1
        If Not ValidarFilaCaptura(wsRegistro, filaCaptura + i, colFecha, colFase, colComentario, _
            fechasEvento(i), fasesEvento(i), comentariosEvento(i)) Then Exit Sub
    Next i

    siguienteFila = SiguienteFilaLibre(wsEventos, COL_EVENTO_ID)
    siguienteId = SiguienteIdEvento(wsEventos)

    For i = 0 To cantidad - 1
        wsEventos.Cells(siguienteFila + i, COL_EVENTO_ID).Value = siguienteId + i
        wsEventos.Cells(siguienteFila + i, COL_EVENTO_FECHA).Value = fechasEvento(i)
        wsEventos.Cells(siguienteFila + i, COL_EVENTO_FASE).Value = fasesEvento(i)
        wsEventos.Cells(siguienteFila + i, COL_EVENTO_COMENTARIO).Value = comentariosEvento(i)
        wsEventos.Cells(siguienteFila + i, COL_EVENTO_FECHA).NumberFormat = "dd/mm/yyyy"
    Next i

    OrdenarEventos wsEventos
    RenumerarEventos wsEventos
    FormatearTablaEventos wsEventos
    LimpiarCapturaMultiple wsRegistro, filaCaptura, cantidad, colFecha, colFase, colComentario
    EliminarCantidadCaptura
    PrepararFilasCaptura wsRegistro, filaCaptura, 1, colFecha, colFase, colComentario
    CrearLineaTiempoPowerPoint

    If cantidad = 1 Then
        MsgBox "Evento agregado y presentacion actualizada.", vbInformation, "Linea del tiempo"
    Else
        MsgBox cantidad & " eventos agregados y presentacion actualizada.", vbInformation, "Linea del tiempo"
    End If
End Sub

Public Sub eliminarALineaTiempo()
    Dim wsEventos As Worksheet
    Dim filaEvento As Long
    Dim ultimaFila As Long
    Dim respuesta As VbMsgBoxResult
    Dim descripcionEvento As String
    Dim textoId As String
    Dim idEvento As Long
    Dim textoCantidad As String
    Dim cantidad As Long
    Dim i As Long
    Dim eliminados As Long

    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)
    ultimaFila = UltimaFilaConDatos(wsEventos, COL_EVENTO_ID)

    If ultimaFila < 2 Then
        MsgBox "No hay eventos para eliminar.", vbExclamation, "Eliminar eventos"
        Exit Sub
    End If

    textoCantidad = Trim$(InputBox("Ingresa el numero de eventos que deseas eliminar:", "Eliminar eventos", "1"))
    If textoCantidad = vbNullString Then Exit Sub
    If Not EsEnteroPositivo(textoCantidad) Then
        MsgBox "La cantidad debe ser un numero entero positivo.", vbExclamation, "Cantidad invalida"
        Exit Sub
    End If
    cantidad = CLng(textoCantidad)

    If cantidad > (ultimaFila - 1) Then
        MsgBox "No puedes eliminar " & cantidad & " eventos porque " & _
            DescribirEventosExistentes(ultimaFila - 1) & ".", vbExclamation, "Cantidad mayor que los eventos existentes"
        Exit Sub
    End If

    For i = 1 To cantidad
        textoId = Trim$(InputBox("Escribe el ID del evento " & i & " de " & cantidad & ":", "Eliminar eventos"))
        If textoId = vbNullString Then Exit For
        If Not EsEnteroPositivo(textoId) Then
            MsgBox "El ID debe ser un numero entero positivo.", vbExclamation, "ID invalido"
        Else
            idEvento = CLng(textoId)
            filaEvento = FilaPorIdEvento(wsEventos, idEvento)
            If filaEvento = 0 Then
                MsgBox "No existe un evento con el ID " & idEvento & ".", vbExclamation, "ID no encontrado"
            Else
                descripcionEvento = "ID " & idEvento & ": " & _
                    CStr(wsEventos.Cells(filaEvento, COL_EVENTO_FECHA).Text) & " - " & _
                    CStr(wsEventos.Cells(filaEvento, COL_EVENTO_FASE).Value) & " - " & _
                    CStr(wsEventos.Cells(filaEvento, COL_EVENTO_COMENTARIO).Value)
                respuesta = MsgBox("Se eliminara el siguiente evento:" & vbCrLf & vbCrLf & descripcionEvento & vbCrLf & vbCrLf & _
                    "Selecciona Si para continuar o No para cancelar.", vbQuestion + vbYesNo, "Confirmar eliminacion")
                If respuesta = vbYes Then
                    wsEventos.Rows(filaEvento).Delete
                    eliminados = eliminados + 1
                End If
            End If
        End If
    Next i

    If eliminados = 0 Then Exit Sub

    If UltimaFilaConDatos(wsEventos, COL_EVENTO_ID) >= 2 Then
        OrdenarEventos wsEventos
        RenumerarEventos wsEventos
        FormatearTablaEventos wsEventos
        CrearLineaTiempoPowerPoint
    Else
        FormatearTablaEventos wsEventos
        LimpiarPowerPointSinEventos
    End If

    If eliminados = 1 Then
        MsgBox "Evento eliminado y presentacion actualizada.", vbInformation, "Eliminar eventos"
    Else
        MsgBox eliminados & " eventos eliminados y presentacion actualizada.", vbInformation, "Eliminar eventos"
    End If
End Sub

Public Sub verPresentacion()
    Dim pptApp As Object
    Dim pptPres As Object
    Dim rutaPpt As String
    Dim wsEventos As Worksheet
    Dim ultimaFila As Long

    On Error GoTo ErrorAbrir

    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)
    ultimaFila = UltimaFilaConDatos(wsEventos, COL_EVENTO_ID)

    If ultimaFila < 2 Then
        MsgBox "No hay eventos registrados en la hoja Eventos." & vbCrLf & vbCrLf & _
            "Agrega al menos un evento antes de generar la presentacion.", _
            vbExclamation, "Sin eventos"
        Exit Sub
    End If

    ' Siempre crea o actualiza el archivo con los eventos actuales.
    CrearLineaTiempoPowerPoint

    rutaPpt = RutaPowerPoint()

    If rutaPpt = vbNullString Then Exit Sub
    If Not CarpetaPowerPointDisponible(rutaPpt) Then Exit Sub

    If Not ArchivoExiste(rutaPpt) Then
        MsgBox "No se pudo generar la presentacion." & vbCrLf & vbCrLf & _
            "Verifica que PowerPoint este instalado y que la carpeta local este disponible.", _
            vbExclamation, "Presentacion no generada"
        Exit Sub
    End If

    Set pptApp = ObtenerPowerPoint()
    pptApp.Visible = True
    Set pptPres = AbrirOPresentacion(pptApp, rutaPpt)

    On Error Resume Next
    pptApp.Activate
    pptPres.Windows(1).Activate
    On Error GoTo 0
    Exit Sub

ErrorAbrir:
    MsgBox "No se pudo abrir la presentacion." & vbCrLf & vbCrLf & _
        "Ruta:" & vbCrLf & rutaPpt & vbCrLf & vbCrLf & _
        "Detalle: " & Err.Description, vbExclamation, "Error al abrir"
End Sub

Private Sub CrearLineaTiempoPowerPoint()
    Dim wsEventos As Worksheet
    Dim ultimaFila As Long
    Dim totalEventos As Long
    Dim pptApp As Object
    Dim pptPres As Object
    Dim rutaPpt As String

    On Error GoTo ErrorGeneracion

    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)

    OrdenarEventos wsEventos
    RenumerarEventos wsEventos
    FormatearTablaEventos wsEventos

    ultimaFila = UltimaFilaConDatos(wsEventos, COL_EVENTO_ID)
    If ultimaFila < 2 Then
        LimpiarPowerPointSinEventos
        Exit Sub
    End If

    totalEventos = ContarEventosVisuales(wsEventos)
    If totalEventos = 0 Then
        LimpiarPowerPointSinEventos
        MsgBox "No hay eventos con fase " & NombreFasePlaneacion() & ", Desarrollo o Pruebas para mostrar.", _
            vbExclamation, "Sin eventos visibles"
        Exit Sub
    End If
    rutaPpt = RutaPowerPoint()
    If rutaPpt = vbNullString Then Exit Sub
    If Not CarpetaPowerPointDisponible(rutaPpt) Then Exit Sub

    Set pptApp = ObtenerPowerPoint()
    pptApp.Visible = True

    If Not ArchivoExiste(rutaPpt) Then
        Set pptPres = CrearPresentacionBase(pptApp, rutaPpt)
    Else
        Set pptPres = AbrirOPresentacion(pptApp, rutaPpt)
    End If

    If pptPres Is Nothing Then Exit Sub
    If PresentacionEnSoloLectura(pptPres, rutaPpt) Then Exit Sub

    If pptPres.Slides.Count < DIAPO_PRIMERA_LINEA Then
        CompletarPresentacionBase pptPres
    End If

    EliminarDiapositivasGeneradas pptPres
    CrearDiapositivasDesdeEventos pptPres, wsEventos, totalEventos
    If Not GuardarPresentacion(pptPres, rutaPpt) Then Exit Sub
    Exit Sub

ErrorGeneracion:
    MsgBox "No se pudo generar la linea del tiempo." & vbCrLf & vbCrLf & _
        "Detalle: " & Err.Description, vbExclamation, "Error PowerPoint"
End Sub

Private Function ObtenerFechaNormalizada(ByVal celdaFecha As Range, ByRef fechaSalida As Date) As Boolean
    Dim valor As Variant
    Dim texto As String
    Dim textoNormal As String
    Dim tokens() As String
    Dim numeros(1 To 3) As Long
    Dim totalNumeros As Long
    Dim dia As Long
    Dim mes As Long
    Dim anio As Long
    Dim i As Long
    Dim token As String

    On Error GoTo FechaInvalida

    valor = celdaFecha.Value2
    texto = Trim$(CStr(celdaFecha.Text))
    If texto = vbNullString Then texto = Trim$(CStr(celdaFecha.Value))

    If IsNumeric(valor) And CDbl(valor) > 0 And CDbl(valor) < 2958466 Then
        fechaSalida = DateSerial(1899, 12, 30) + CDbl(valor)
        ObtenerFechaNormalizada = True
        Exit Function
    End If

    If IsDate(texto) Then
        fechaSalida = CDate(texto)
        ObtenerFechaNormalizada = True
        Exit Function
    End If

    textoNormal = LCase$(QuitarAcentos(texto))
    textoNormal = Replace(textoNormal, ",", " ")
    textoNormal = Replace(textoNormal, "-", " ")
    textoNormal = Replace(textoNormal, "/", " ")
    textoNormal = Replace(textoNormal, ".", " ")
    textoNormal = Replace(textoNormal, " de ", " ")
    textoNormal = Application.WorksheetFunction.Trim(textoNormal)

    If Len(SoloDigitos(textoNormal)) = 8 And InStr(textoNormal, " ") = 0 Then
        If CLng(Left$(textoNormal, 4)) >= 1900 Then
            anio = CLng(Left$(textoNormal, 4))
            mes = CLng(Mid$(textoNormal, 5, 2))
            dia = CLng(Right$(textoNormal, 2))
        Else
            dia = CLng(Left$(textoNormal, 2))
            mes = CLng(Mid$(textoNormal, 3, 2))
            anio = CLng(Right$(textoNormal, 4))
        End If
        GoTo ConstruirFecha
    End If

    tokens = Split(textoNormal, " ")
    For i = LBound(tokens) To UBound(tokens)
        token = Trim$(tokens(i))
        If token <> vbNullString Then
            If IsNumeric(token) Then
                totalNumeros = totalNumeros + 1
                If totalNumeros <= 3 Then numeros(totalNumeros) = CLng(token)
            ElseIf MesDesdeTexto(token) > 0 Then
                mes = MesDesdeTexto(token)
            End If
        End If
    Next i

    If mes > 0 And totalNumeros >= 2 Then
        dia = numeros(1)
        anio = numeros(totalNumeros)
    ElseIf totalNumeros >= 3 Then
        If numeros(1) >= 1900 Then
            anio = numeros(1)
            mes = numeros(2)
            dia = numeros(3)
        Else
            dia = numeros(1)
            mes = numeros(2)
            anio = numeros(3)
        End If
    Else
        GoTo FechaInvalida
    End If

    If anio < 100 Then
        If anio <= 30 Then
            anio = 2000 + anio
        Else
            anio = 1900 + anio
        End If
    End If

ConstruirFecha:
    fechaSalida = DateSerial(anio, mes, dia)
    If Day(fechaSalida) <> dia Or Month(fechaSalida) <> mes Or Year(fechaSalida) <> anio Then GoTo FechaInvalida

    ObtenerFechaNormalizada = True
    Exit Function

FechaInvalida:
    ObtenerFechaNormalizada = False
End Function

Private Function FilaEncabezadoFormulario(ByVal ws As Worksheet) As Long
    Dim fila As Long

    For fila = 1 To 50
        If ColumnaPorEncabezado(ws, "Fecha", fila) > 0 And _
            ColumnaPorEncabezado(ws, "Fase", fila) > 0 And _
            ColumnaPorEncabezado(ws, "Comentario", fila) > 0 Then
            FilaEncabezadoFormulario = fila
            Exit Function
        End If
    Next fila
End Function

Private Function ColumnaPorEncabezado(ByVal ws As Worksheet, ByVal encabezado As String, ByVal filaEncabezado As Long) As Long
    Dim celda As Range

    If filaEncabezado <= 0 Then Exit Function

    For Each celda In ws.Rows(filaEncabezado).Cells
        If Trim$(LCase$(CStr(celda.Value))) = LCase$(encabezado) Then
            ColumnaPorEncabezado = celda.Column
            Exit Function
        End If

        If celda.Column >= 20 Then Exit For
    Next celda
End Function

Private Function SiguienteFilaLibre(ByVal ws As Worksheet, ByVal columna As Variant) As Long
    SiguienteFilaLibre = UltimaFilaConDatos(ws, columna) + 1
    If SiguienteFilaLibre < 2 Then SiguienteFilaLibre = 2
End Function

Private Function UltimaFilaConDatos(ByVal ws As Worksheet, ByVal columna As Variant) As Long
    UltimaFilaConDatos = ws.Cells(ws.Rows.Count, columna).End(xlUp).Row
End Function

Private Function SiguienteIdEvento(ByVal ws As Worksheet) As Long
    Dim ultimaFila As Long
    Dim valorMaximo As Variant

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    If ultimaFila < 2 Then
        SiguienteIdEvento = 1
    Else
        valorMaximo = Application.Max(ws.Range(COL_EVENTO_ID & "2:" & COL_EVENTO_ID & ultimaFila))
        SiguienteIdEvento = CLng(valorMaximo) + 1
    End If
End Function

Private Function EsEnteroPositivo(ByVal texto As String) As Boolean
    Dim i As Long
    Dim caracter As String

    If texto = vbNullString Then Exit Function

    For i = 1 To Len(texto)
        caracter = Mid$(texto, i, 1)
        If Not caracter Like "#" Then Exit Function
    Next i

    EsEnteroPositivo = (CLng(texto) > 0)
End Function

Private Function DescribirEventosExistentes(ByVal cantidad As Long) As String
    If cantidad = 1 Then
        DescribirEventosExistentes = "solo existe 1 evento"
    Else
        DescribirEventosExistentes = "solo existen " & cantidad & " eventos"
    End If
End Function

Private Function FilaPorIdEvento(ByVal ws As Worksheet, ByVal idEvento As Long) As Long
    Dim ultimaFila As Long
    Dim fila As Long

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)

    For fila = 2 To ultimaFila
        If Val(ws.Cells(fila, COL_EVENTO_ID).Value) = idEvento Then
            FilaPorIdEvento = fila
            Exit Function
        End If
    Next fila
End Function

Private Sub AplicarFijacionBotones(ByVal ws As Worksheet)
    Dim forma As Shape
    Dim accion As String

    For Each forma In ws.Shapes
        On Error Resume Next
        accion = LCase$(forma.OnAction)
        On Error GoTo 0
        If accion <> vbNullString Then
            forma.Placement = xlFreeFloating
            forma.Line.ForeColor.RGB = RGB(15, 42, 67)
            forma.Line.Weight = 1.5
            If InStr(accion, "agregaralineatiempo") > 0 Then
                forma.Fill.ForeColor.RGB = RGB(0, 114, 124)
            ElseIf InStr(accion, "eliminaralineatiempo") > 0 Then
                forma.Fill.ForeColor.RGB = RGB(192, 0, 0)
            ElseIf InStr(accion, "verpresentacion") > 0 Then
                forma.Fill.ForeColor.RGB = RGB(59, 125, 35)
            End If
            On Error Resume Next
            With forma.TextFrame2.TextRange.Font
                .Name = "Calibri"
                .Size = 11
                .Bold = True
                .Fill.ForeColor.RGB = RGB(255, 255, 255)
            End With
            forma.TextFrame2.TextRange.ParagraphFormat.Alignment = 2
            forma.TextFrame2.VerticalAnchor = 3
            On Error GoTo 0
        End If
        accion = vbNullString
    Next forma
End Sub

Private Sub PrepararFilasCaptura(ByVal ws As Worksheet, ByVal filaInicial As Long, ByVal cantidad As Long, _
    ByVal colFecha As Long, ByVal colFase As Long, ByVal colComentario As Long)

    Dim fila As Long
    Dim rangoModelo As Range
    Dim rangoDestino As Range

    Set rangoModelo = ws.Range(ws.Cells(filaInicial, colFecha), ws.Cells(filaInicial, colComentario))

    For fila = filaInicial To filaInicial + cantidad - 1
        Set rangoDestino = ws.Range(ws.Cells(fila, colFecha), ws.Cells(fila, colComentario))
        If fila > filaInicial Then
            rangoDestino.ClearContents
            rangoModelo.Copy
            rangoDestino.PasteSpecial xlPasteFormats
            On Error Resume Next
            rangoDestino.PasteSpecial xlPasteValidation
            On Error GoTo 0
        End If

        With rangoDestino
            .Borders.LineStyle = xlContinuous
            .Borders.Weight = xlThin
            .VerticalAlignment = xlCenter
        End With
        ws.Cells(fila, colFecha).NumberFormat = "dd/mm/yyyy"
        AplicarValidacionFecha ws.Cells(fila, colFecha)
        AplicarValidacionFase ws.Cells(fila, colFase)
        AplicarValidacionComentario ws.Cells(fila, colComentario)
        With ws.Cells(fila, colComentario)
            .WrapText = True
            .Font.Name = "Calibri"
            .Font.Size = 11
            .Font.Bold = False
            .Font.Italic = False
        End With
        ws.Rows(fila).AutoFit
    Next fila

    Application.CutCopyMode = False
    AplicarFijacionBotones ws
End Sub

Private Function FilaCapturaTieneDatos(ByVal ws As Worksheet, ByVal fila As Long, _
    ByVal colFecha As Long, ByVal colFase As Long, ByVal colComentario As Long) As Boolean

    FilaCapturaTieneDatos = Trim$(CStr(ws.Cells(fila, colFecha).Value)) <> vbNullString And _
        Trim$(CStr(ws.Cells(fila, colFase).Value)) <> vbNullString And _
        Trim$(CStr(ws.Cells(fila, colComentario).Value)) <> vbNullString
End Function

Private Sub AplicarValidacionFechaFormulario(ByVal ws As Worksheet)
    Dim filaEncabezado As Long
    Dim filaCaptura As Long
    Dim colFecha As Long
    Dim cantidad As Long
    Dim i As Long

    filaEncabezado = FilaEncabezadoFormulario(ws)
    If filaEncabezado = 0 Then Exit Sub

    colFecha = ColumnaPorEncabezado(ws, "Fecha", filaEncabezado)
    If colFecha = 0 Then Exit Sub

    filaCaptura = filaEncabezado + 1
    cantidad = CantidadCapturaPendiente()
    If cantidad < 1 Then cantidad = 1

    For i = 0 To cantidad - 1
        ws.Cells(filaCaptura + i, colFecha).NumberFormat = "dd/mm/yyyy"
        AplicarValidacionFecha ws.Cells(filaCaptura + i, colFecha)
    Next i
End Sub

Private Sub AplicarValidacionFecha(ByVal celda As Range)
    On Error Resume Next
    celda.Validation.Delete
    On Error GoTo 0

    With celda.Validation
        .Add Type:=xlValidateDate, AlertStyle:=xlValidAlertStop, _
            Operator:=xlBetween, Formula1:=CStr(CLng(FechaMinimaValida())), _
            Formula2:=CStr(CLng(FechaMaximaValida()))
        .IgnoreBlank = True
        .ShowInput = True
        .InputTitle = "Rango de fechas"
        .InputMessage = "Ingresa una fecha del " & TextoRangoFechasValidas() & "."
        .ShowError = True
        .ErrorTitle = "Fecha fuera del rango"
        .ErrorMessage = MensajeFechaInvalida()
    End With
End Sub

Private Function FechaMinimaValida() As Date
    FechaMinimaValida = DateSerial(FECHA_MINIMA_ANIO, FECHA_MINIMA_MES, FECHA_MINIMA_DIA)
End Function

Private Function FechaMaximaValida() As Date
    FechaMaximaValida = DateSerial(FECHA_MAXIMA_ANIO, FECHA_MAXIMA_MES, FECHA_MAXIMA_DIA)
End Function

Private Function TextoRangoFechasValidas() As String
    TextoRangoFechasValidas = Format$(FechaMinimaValida(), "dd/mm/yyyy") & " al " & _
        Format$(FechaMaximaValida(), "dd/mm/yyyy")
End Function

Private Function MensajeFechaInvalida() As String
    MensajeFechaInvalida = "La fecha no es v" & ChrW(225) & "lida o est" & ChrW(225) & _
        " fuera del rango permitido." & vbLf & _
        "Rango v" & ChrW(225) & "lido: " & TextoRangoFechasValidas() & "."
End Function

Private Sub AplicarValidacionFase(ByVal celda As Range)
    Dim separador As String
    Dim listaFases As String

    separador = Application.International(xlListSeparator)
    listaFases = NombreFasePlaneacion() & separador & "Desarrollo" & separador & "Pruebas"

    On Error Resume Next
    celda.Validation.Delete
    On Error GoTo 0

    With celda.Validation
        .Add Type:=xlValidateList, AlertStyle:=xlValidAlertStop, _
            Operator:=xlBetween, Formula1:=listaFases
        .IgnoreBlank = True
        .InCellDropdown = True
        .ShowError = True
        .ErrorTitle = "Fase invalida"
        .ErrorMessage = "Selecciona " & NombreFasePlaneacion() & ", Desarrollo o Pruebas."
    End With
End Sub

Private Sub AplicarValidacionComentario(ByVal celda As Range)
    On Error Resume Next
    celda.Validation.Delete
    On Error GoTo 0

    With celda.Validation
        .Add Type:=xlValidateTextLength, AlertStyle:=xlValidAlertStop, _
            Operator:=xlLessEqual, Formula1:=CStr(MAX_CARACTERES_COMENTARIO)
        .IgnoreBlank = True
        .ShowError = True
        .ErrorTitle = "Comentario demasiado largo"
        .ErrorMessage = "El comentario puede tener como maximo " & _
            MAX_CARACTERES_COMENTARIO & " caracteres."
    End With
End Sub

Private Function ValidarFilaCaptura(ByVal ws As Worksheet, ByVal fila As Long, _
    ByVal colFecha As Long, ByVal colFase As Long, ByVal colComentario As Long, _
    ByRef fechaEvento As Date, ByRef faseEvento As String, ByRef comentario As String) As Boolean

    If Not ObtenerFechaNormalizada(ws.Cells(fila, colFecha), fechaEvento) Then
        MsgBox MensajeFechaInvalida() & vbCrLf & vbCrLf & _
            "Revisa la fecha de la fila " & fila & ".", _
            vbExclamation, "Fecha fuera del rango"
        ws.Cells(fila, colFecha).Select
        Exit Function
    End If

    If fechaEvento < FechaMinimaValida() Or fechaEvento > FechaMaximaValida() Then
        MsgBox MensajeFechaInvalida() & vbCrLf & vbCrLf & _
            "Revisa la fecha de la fila " & fila & ".", _
            vbExclamation, "Fecha fuera del rango"
        ws.Cells(fila, colFecha).Select
        Exit Function
    End If

    faseEvento = Trim$(CStr(ws.Cells(fila, colFase).Value))
    comentario = Trim$(CStr(ws.Cells(fila, colComentario).Value))

    If faseEvento = vbNullString Then
        MsgBox "Selecciona una fase en la fila " & fila & ".", vbExclamation, "Evento incompleto"
        ws.Cells(fila, colFase).Select
        Exit Function
    End If

    faseEvento = NormalizarFase(faseEvento)
    If faseEvento = vbNullString Then
        MsgBox "La fase de la fila " & fila & " debe ser " & NombreFasePlaneacion() & _
            ", Desarrollo o Pruebas.", _
            vbExclamation, "Fase invalida"
        ws.Cells(fila, colFase).Select
        Exit Function
    End If

    If comentario = vbNullString Then
        MsgBox "Escribe un comentario en la fila " & fila & ".", vbExclamation, "Evento incompleto"
        ws.Cells(fila, colComentario).Select
        Exit Function
    End If

    If Len(comentario) > MAX_CARACTERES_COMENTARIO Then
        MsgBox "El comentario de la fila " & fila & " debe tener como maximo " & _
            MAX_CARACTERES_COMENTARIO & " caracteres.", vbExclamation, "Comentario demasiado largo"
        ws.Cells(fila, colComentario).Select
        Exit Function
    End If

    ValidarFilaCaptura = True
End Function

Private Function NombreFasePlaneacion() As String
    NombreFasePlaneacion = "Planeaci" & ChrW(243) & "n"
End Function

Private Function NormalizarFase(ByVal faseEvento As String) As String
    Select Case LCase$(Trim$(QuitarAcentos(faseEvento)))
        Case "planeacion", "verde"
            NormalizarFase = NombreFasePlaneacion()
        Case "desarrollo", "naranja", "amarillo"
            NormalizarFase = "Desarrollo"
        Case "pruebas", "rojo"
            NormalizarFase = "Pruebas"
    End Select
End Function

Private Sub LimpiarCapturaMultiple(ByVal ws As Worksheet, ByVal filaInicial As Long, ByVal cantidad As Long, _
    ByVal colFecha As Long, ByVal colFase As Long, ByVal colComentario As Long)

    Dim rangoAdicional As Range
    Dim fila As Long

    ' La primera fila conserva el formato permanente del formulario.
    ws.Range(ws.Cells(filaInicial, colFecha), ws.Cells(filaInicial, colComentario)).ClearContents

    ' Las filas adicionales recuperan el aspecto normal de la hoja.
    If cantidad > 1 Then
        Set rangoAdicional = ws.Range(ws.Cells(filaInicial + 1, colFecha), _
            ws.Cells(filaInicial + cantidad - 1, colComentario))
        rangoAdicional.Clear

        For fila = filaInicial + 1 To filaInicial + cantidad - 1
            ws.Rows(fila).RowHeight = ws.StandardHeight
        Next fila
    End If
End Sub

Private Function CantidadCapturaPendiente() As Long
    On Error Resume Next
    CantidadCapturaPendiente = CLng(Evaluate(ThisWorkbook.Names(NOMBRE_CANTIDAD_PENDIENTE).RefersTo))
    On Error GoTo 0
End Function

Private Sub GuardarCantidadCaptura(ByVal cantidad As Long)
    EliminarCantidadCaptura
    ThisWorkbook.Names.Add Name:=NOMBRE_CANTIDAD_PENDIENTE, RefersTo:="=" & cantidad, Visible:=False
End Sub

Private Sub EliminarCantidadCaptura()
    On Error Resume Next
    ThisWorkbook.Names(NOMBRE_CANTIDAD_PENDIENTE).Delete
    On Error GoTo 0
End Sub

Private Sub OrdenarEventos(ByVal ws As Worksheet)
    Dim ultimaFila As Long

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    If ultimaFila < 3 Then Exit Sub

    With ws.Sort
        .SortFields.Clear
        .SortFields.Add Key:=ws.Range(COL_EVENTO_FECHA & "2:" & COL_EVENTO_FECHA & ultimaFila), _
            SortOn:=xlSortOnValues, Order:=xlAscending, DataOption:=xlSortNormal
        .SortFields.Add Key:=ws.Range(COL_EVENTO_ID & "2:" & COL_EVENTO_ID & ultimaFila), _
            SortOn:=xlSortOnValues, Order:=xlAscending, DataOption:=xlSortNormal
        .SetRange ws.Range("A1:D" & ultimaFila)
        .Header = xlYes
        .Apply
    End With
End Sub

Private Sub RenumerarEventos(ByVal ws As Worksheet)
    Dim ultimaFila As Long
    Dim fila As Long

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    If ultimaFila < 2 Then Exit Sub

    For fila = 2 To ultimaFila
        ws.Cells(fila, COL_EVENTO_ID).Value = fila - 1
    Next fila
End Sub

Private Sub FormatearTablaEventos(ByVal ws As Worksheet)
    Dim ultimaFila As Long
    Dim rangoTabla As Range
    Dim rangoLimpieza As Range
    Dim fila As Long
    Dim faseNormalizada As String

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    If ultimaFila < 1 Then ultimaFila = 1

    ' Migra automaticamente las etiquetas antiguas basadas en colores.
    For fila = 2 To ultimaFila
        faseNormalizada = NormalizarFase(CStr(ws.Cells(fila, COL_EVENTO_FASE).Value))
        If faseNormalizada <> vbNullString Then
            ws.Cells(fila, COL_EVENTO_FASE).Value = faseNormalizada
        End If
    Next fila

    Set rangoLimpieza = ws.Range("A1:D" & Application.WorksheetFunction.Max(ultimaFila + 20, 50))
    rangoLimpieza.Borders.LineStyle = xlNone

    Set rangoTabla = ws.Range("A1:D" & ultimaFila)
    ws.Range("A1:D1").Value = Array("ID", "Fecha", "Fase", "Comentario")

    With ws.Range("A1:D1")
        .Interior.Color = RGB(21, 96, 130)
        .Font.Color = RGB(255, 255, 255)
        .Font.Bold = True
        .HorizontalAlignment = xlCenter
    End With

    With rangoTabla.Borders
        .LineStyle = xlContinuous
        .Weight = xlThin
        .Color = RGB(0, 0, 0)
    End With

    If ultimaFila >= 2 Then
        ws.Range("A2:A" & ultimaFila).HorizontalAlignment = xlRight
        ws.Range("B2:B" & ultimaFila).NumberFormat = "dd/mm/yyyy"
        ws.Range("B2:C" & ultimaFila).HorizontalAlignment = xlLeft
        ws.Range("D2:D" & ultimaFila).HorizontalAlignment = xlLeft
        ws.Range("D2:D" & ultimaFila).WrapText = True
        ws.Range("A2:D" & ultimaFila).Rows.AutoFit
    End If

    ws.Columns("A").ColumnWidth = 10
    ws.Columns("B").ColumnWidth = 12
    ws.Columns("C").ColumnWidth = 14
    ws.Columns("D").ColumnWidth = 90

    If ws.AutoFilterMode Then ws.AutoFilterMode = False
    rangoTabla.AutoFilter
End Sub

Private Function ObtenerPowerPoint() As Object
    On Error Resume Next
    Set ObtenerPowerPoint = GetObject(, "PowerPoint.Application")
    On Error GoTo 0

    If ObtenerPowerPoint Is Nothing Then
        Set ObtenerPowerPoint = CreateObject("PowerPoint.Application")
    End If
End Function

Private Function RutaPowerPoint() As String
    Dim carpetaDocumentos As String
    Dim carpetaSalida As String

    carpetaDocumentos = CreateObject("WScript.Shell").SpecialFolders("MyDocuments")
    carpetaSalida = carpetaDocumentos & "\Linea del Tiempo"

    If Not CarpetaExiste(carpetaSalida) Then CrearCarpetaSiNoExiste carpetaSalida
    If Not CarpetaExiste(carpetaSalida) Then Exit Function

    RutaPowerPoint = carpetaSalida & "\" & ARCHIVO_POWERPOINT_SALIDA
End Function

Private Function ArchivoExiste(ByVal rutaArchivo As String) As Boolean
    On Error Resume Next
    ArchivoExiste = CreateObject("Scripting.FileSystemObject").FileExists(rutaArchivo)
    On Error GoTo 0
End Function

Private Function CarpetaExiste(ByVal rutaCarpeta As String) As Boolean
    On Error Resume Next
    CarpetaExiste = CreateObject("Scripting.FileSystemObject").FolderExists(rutaCarpeta)
    On Error GoTo 0
End Function

Private Sub CrearCarpetaSiNoExiste(ByVal rutaCarpeta As String)
    On Error GoTo ErrorCrear
    CreateObject("Scripting.FileSystemObject").CreateFolder rutaCarpeta
    Exit Sub
ErrorCrear:
    MsgBox "No se pudo crear la carpeta local:" & vbCrLf & vbCrLf & rutaCarpeta & vbCrLf & vbCrLf & _
        "Detalle: " & Err.Description, vbExclamation, "Error de carpeta"
End Sub

Private Function CarpetaPowerPointDisponible(ByVal rutaPpt As String) As Boolean
    Dim carpetaSalida As String
    Dim posicionSeparador As Long

    On Error GoTo CarpetaNoDisponible

    If rutaPpt = vbNullString Then Exit Function

    posicionSeparador = InStrRev(rutaPpt, Application.PathSeparator)
    If posicionSeparador = 0 Then GoTo CarpetaNoDisponible

    carpetaSalida = Left$(rutaPpt, posicionSeparador - 1)

    If Dir$(carpetaSalida, vbDirectory) = vbNullString Then GoTo CarpetaNoDisponible

    CarpetaPowerPointDisponible = True
    Exit Function

CarpetaNoDisponible:
    MsgBox "No se encontro la carpeta donde debe guardarse la presentacion." & vbCrLf & vbCrLf & _
        "Revisa que la carpeta local Documentos\Linea del Tiempo este disponible:" & vbCrLf & vbCrLf & _
        carpetaSalida, vbExclamation, "Carpeta no disponible"
End Function

Private Function AbrirOPresentacion(ByVal pptApp As Object, ByVal rutaPpt As String) As Object
    Dim presentacion As Object

    For Each presentacion In pptApp.Presentations
        If StrComp(presentacion.FullName, rutaPpt, vbTextCompare) = 0 Then
            Set AbrirOPresentacion = presentacion
            Exit Function
        End If

        If StrComp(presentacion.Name, ARCHIVO_POWERPOINT_SALIDA, vbTextCompare) = 0 Then
            Set AbrirOPresentacion = presentacion
            Exit Function
        End If
    Next presentacion

    Set AbrirOPresentacion = pptApp.Presentations.Open(rutaPpt)
End Function

Private Function CrearPresentacionBase(ByVal pptApp As Object, ByVal rutaPpt As String) As Object
    Dim pptPres As Object

    Set pptPres = pptApp.Presentations.Add
    CompletarPresentacionBase pptPres
    If Not GuardarPresentacionComo(pptPres, rutaPpt) Then Exit Function

    Set CrearPresentacionBase = pptPres
End Function

Private Function PresentacionEnSoloLectura(ByVal pptPres As Object, ByVal rutaPpt As String) As Boolean
    Dim esSoloLectura As Boolean

    On Error Resume Next
    esSoloLectura = CBool(pptPres.ReadOnly)
    If Err.Number <> 0 Then
        Err.Clear
        esSoloLectura = False
    End If
    On Error GoTo 0

    If esSoloLectura Then
        MsgBox "La presentacion esta abierta en modo de solo lectura y no se puede actualizar." & vbCrLf & vbCrLf & _
            "Cierra la presentacion o abrela desde una carpeta con permisos de edicion:" & vbCrLf & vbCrLf & _
            rutaPpt, vbExclamation, "Presentacion en modo de solo lectura"
    End If

    PresentacionEnSoloLectura = esSoloLectura
End Function

Private Function GuardarPresentacion(ByVal pptPres As Object, ByVal rutaPpt As String) As Boolean
    On Error GoTo ErrorGuardar

    If PresentacionEnSoloLectura(pptPres, rutaPpt) Then Exit Function

    pptPres.Save
    GuardarPresentacion = True
    Exit Function

ErrorGuardar:
    MsgBox "No se pudo guardar la presentacion." & vbCrLf & vbCrLf & _
        "Si esta abierta en PowerPoint, cierrala o comprueba que no este en modo de solo lectura." & vbCrLf & vbCrLf & _
        "Ruta:" & vbCrLf & rutaPpt & vbCrLf & vbCrLf & _
        "Detalle: " & Err.Description, vbExclamation, "Error al guardar"
End Function

Private Function GuardarPresentacionComo(ByVal pptPres As Object, ByVal rutaPpt As String) As Boolean
    On Error GoTo ErrorGuardar

    pptPres.SaveAs rutaPpt
    GuardarPresentacionComo = True
    Exit Function

ErrorGuardar:
    MsgBox "No se pudo crear o guardar la presentacion." & vbCrLf & vbCrLf & _
        "Revisa que la carpeta este disponible y que el archivo no este abierto en modo de solo lectura." & vbCrLf & vbCrLf & _
        "Ruta:" & vbCrLf & rutaPpt & vbCrLf & vbCrLf & _
        "Detalle: " & Err.Description, vbExclamation, "Error al guardar"
End Function

Private Sub CerrarPresentacionSiAbierta(ByVal pptApp As Object, ByVal rutaPpt As String)
    Dim i As Long

    For i = pptApp.Presentations.Count To 1 Step -1
        If StrComp(pptApp.Presentations(i).FullName, rutaPpt, vbTextCompare) = 0 Then
            pptApp.Presentations(i).Close
            Exit For
        End If
    Next i
End Sub

Private Sub CompletarPresentacionBase(ByVal pptPres As Object)
    Do While pptPres.Slides.Count < DIAPO_PRIMERA_LINEA
        pptPres.Slides.Add pptPres.Slides.Count + 1, 12
    Loop

    If pptPres.Slides(DIAPO_PORTADA).Shapes.Count = 0 Then
        AgregarTitulo pptPres.Slides(DIAPO_PORTADA), "Portada Linea del Tiempo"
    End If
End Sub

Private Sub LimpiarPowerPointSinEventos()
    Dim pptApp As Object
    Dim rutaPpt As String

    rutaPpt = RutaPowerPoint()
    If rutaPpt = vbNullString Then Exit Sub

    On Error Resume Next
    Set pptApp = ObtenerPowerPoint()
    If Not pptApp Is Nothing Then CerrarPresentacionSiAbierta pptApp, rutaPpt
    If ArchivoExiste(rutaPpt) Then Kill rutaPpt
    On Error GoTo 0
End Sub

Private Sub EliminarDiapositivasGeneradas(ByVal pptPres As Object)
    Dim i As Long

    For i = pptPres.Slides.Count To DIAPO_PRIMERA_LINEA + 1 Step -1
        If pptPres.Slides(i).Tags(ETIQUETA_GENERADA) = "si" Then
            pptPres.Slides(i).Delete
        End If
    Next i
End Sub

Private Sub CrearDiapositivasDesdeEventos(ByVal pptPres As Object, ByVal ws As Worksheet, ByVal totalEventos As Long)
    Dim totalDiapositivas As Long
    Dim numeroDiapositiva As Long
    Dim slideActual As Object
    Dim filasEventos As Variant

    totalDiapositivas = Application.WorksheetFunction.RoundUp(totalEventos / EVENTOS_POR_DIAPOSITIVA, 0)
    filasEventos = FilasEventosVisuales(ws, totalEventos)

    For numeroDiapositiva = 1 To totalDiapositivas
        If numeroDiapositiva = 1 Then
            Set slideActual = pptPres.Slides(DIAPO_PRIMERA_LINEA)
            LimpiarDiapositiva slideActual
        Else
            Set slideActual = CrearDiapositivaGenerada(pptPres)
        End If

        DibujarDiapositivaEventos slideActual, ws, numeroDiapositiva, totalEventos, filasEventos
    Next numeroDiapositiva
End Sub

Private Function CrearDiapositivaGenerada(ByVal pptPres As Object) As Object
    Dim slide As Object

    Set slide = pptPres.Slides.Add(pptPres.Slides.Count + 1, 12)
    slide.Layout = 12
    slide.SlideShowTransition.Hidden = False
    slide.Tags.Add ETIQUETA_GENERADA, "si"

    Set CrearDiapositivaGenerada = slide
End Function

Private Sub LimpiarDiapositiva(ByVal slide As Object)
    Dim i As Long

    On Error Resume Next
    slide.Layout = 12
    On Error GoTo 0

    For i = slide.Shapes.Count To 1 Step -1
        slide.Shapes(i).Delete
    Next i
End Sub

Private Sub DibujarDiapositivaEventos(ByVal slide As Object, ByVal ws As Worksheet, _
    ByVal numeroDiapositiva As Long, ByVal totalEventos As Long, ByRef filasEventos As Variant)
    Dim slot As Long
    Dim indiceEvento As Long
    Dim filaEvento As Long
    Dim fechaTexto As String
    Dim faseEvento As String
    Dim comentario As String
    Dim x As Single
    Dim estaArriba As Boolean

    AplicarFondo slide
    AgregarTitulo slide, TituloPresentacion()
    AgregarLineaBase slide, 0, LINEA_Y, slide.Parent.PageSetup.SlideWidth

    For slot = 1 To EVENTOS_POR_DIAPOSITIVA
        indiceEvento = ((numeroDiapositiva - 1) * EVENTOS_POR_DIAPOSITIVA) + slot

        If indiceEvento <= totalEventos Then
            filaEvento = filasEventos(indiceEvento)
            x = PosicionEventoX(slot)
            estaArriba = EventoVaArriba(slot)
            fechaTexto = FechaLargaEspanol(ws.Cells(filaEvento, COL_EVENTO_FECHA).Value)
            faseEvento = CStr(ws.Cells(filaEvento, COL_EVENTO_FASE).Value)
            comentario = CStr(ws.Cells(filaEvento, COL_EVENTO_COMENTARIO).Value)

            AgregarEventoPowerPoint slide, x, LINEA_Y, estaArriba, fechaTexto, faseEvento, comentario, indiceEvento
        End If
    Next slot

    AgregarLeyendaFases slide
    AgregarAvisoConfidencialidad slide
End Sub

Private Function PosicionEventoX(ByVal slot As Long) As Single
    Select Case slot
        Case 1: PosicionEventoX = 120
        Case 2: PosicionEventoX = 264
        Case 3: PosicionEventoX = 408
        Case 4: PosicionEventoX = 552
        Case 5: PosicionEventoX = 696
        Case 6: PosicionEventoX = 840
    End Select
End Function

Private Function TituloPresentacion() As String
    TituloPresentacion = "L" & ChrW(237) & "nea del tiempo para la integraci" & ChrW(243) & "n de plataformas GPS con el PSIM"
End Function

Private Function EventoVaArriba(ByVal slot As Long) As Boolean
    ' Patron fijo en todas las diapositivas: tres eventos arriba y tres abajo.
    EventoVaArriba = (slot Mod 2 = 1)
End Function

Private Sub AgregarEventoPowerPoint(ByVal slide As Object, ByVal x As Single, ByVal yLinea As Single, _
    ByVal estaArriba As Boolean, ByVal fechaTexto As String, ByVal faseEvento As String, _
    ByVal comentario As String, ByVal numeroEvento As Long)
    Dim yEncabezado As Single
    Dim yComentario As Single
    Dim yConector As Single
    Dim altoConector As Single
    Dim conector As Object
    Dim marcador As Object
    Dim encabezado As Object
    Dim comentarioBox As Object
    Dim colorEvento As Long
    Dim colorFondo As Long
    Dim altoRealComentario As Single
    Const ANCHO_BLOQUE As Single = 184
    Const ALTO_ENCABEZADO As Single = 45
    Const ALTO_COMENTARIO_MAX As Single = 145
    Const ALTO_COMENTARIO_MIN As Single = 44

    colorEvento = ColorPorFase(faseEvento)
    colorFondo = ColorFondoPorFase(faseEvento)
    If estaArriba Then
        yEncabezado = 235
        yComentario = yEncabezado - ALTO_COMENTARIO_MAX
        yConector = yEncabezado + ALTO_ENCABEZADO
        altoConector = yLinea - yConector
    Else
        yEncabezado = 318
        yComentario = yEncabezado + ALTO_ENCABEZADO
        yConector = yLinea
        altoConector = yEncabezado - yLinea
    End If

    Set conector = slide.Shapes.AddShape(1, x - 0.75, yConector, 1.5, altoConector)
    conector.Fill.ForeColor.RGB = colorEvento
    conector.Line.Visible = False

    Set marcador = slide.Shapes.AddShape(9, x - 10, yLinea - 10, 20, 20)
    marcador.Fill.ForeColor.RGB = colorEvento
    marcador.Line.ForeColor.RGB = RGB(255, 255, 255)
    marcador.Line.Weight = 1.5
    With marcador.TextFrame.TextRange
        .Text = Format$(numeroEvento, "00")
        .Font.Name = "Calibri"
        .Font.Size = 9
        .Font.Bold = True
        .Font.Color.RGB = RGB(255, 255, 255)
        .ParagraphFormat.Alignment = 2
    End With
    marcador.TextFrame.MarginLeft = 0
    marcador.TextFrame.MarginRight = 0
    marcador.TextFrame.MarginTop = 0
    marcador.TextFrame.MarginBottom = 0
    marcador.TextFrame.VerticalAnchor = 3

    Set encabezado = slide.Shapes.AddShape(1, x - (ANCHO_BLOQUE / 2), yEncabezado, ANCHO_BLOQUE, ALTO_ENCABEZADO)
    encabezado.Fill.ForeColor.RGB = colorEvento
    encabezado.Line.Visible = False
    With encabezado.TextFrame.TextRange
        .Text = fechaTexto
        .Font.Name = "Calibri"
        .Font.Size = 16
        .Font.Bold = True
        .Font.Color.RGB = RGB(255, 255, 255)
        .ParagraphFormat.Alignment = 2
    End With
    encabezado.TextFrame.VerticalAnchor = 3

    Set comentarioBox = slide.Shapes.AddShape(1, x - (ANCHO_BLOQUE / 2), yComentario, ANCHO_BLOQUE, ALTO_COMENTARIO_MAX)
    comentarioBox.Fill.ForeColor.RGB = colorFondo
    comentarioBox.Line.Visible = False
    With comentarioBox.TextFrame.TextRange
        .Text = comentario
        .Font.Name = "Calibri"
        .Font.Size = 12
        .Font.Italic = False
        .Font.Color.RGB = RGB(0, 0, 0)
        .ParagraphFormat.Alignment = 2
    End With
    comentarioBox.TextFrame.MarginLeft = 9
    comentarioBox.TextFrame.MarginRight = 9
    comentarioBox.TextFrame.MarginTop = 8
    comentarioBox.TextFrame.MarginBottom = 8
    comentarioBox.TextFrame.VerticalAnchor = 3
    comentarioBox.TextFrame.WordWrap = True
    comentarioBox.TextFrame.AutoSize = 0

    ' Ajusta el cuadro a la altura real del comentario.
    altoRealComentario = CSng(comentarioBox.TextFrame2.TextRange.BoundHeight) + _
        CSng(comentarioBox.TextFrame.MarginTop) + CSng(comentarioBox.TextFrame.MarginBottom) + 4

    If altoRealComentario < ALTO_COMENTARIO_MIN Then altoRealComentario = ALTO_COMENTARIO_MIN
    If altoRealComentario > ALTO_COMENTARIO_MAX Then altoRealComentario = ALTO_COMENTARIO_MAX

    comentarioBox.Height = altoRealComentario
    If estaArriba Then
        comentarioBox.Top = yEncabezado - altoRealComentario
    Else
        comentarioBox.Top = yEncabezado + ALTO_ENCABEZADO
    End If
End Sub

Private Sub AgregarTitulo(ByVal slide As Object, ByVal texto As String)
    Dim titulo As Object

    Set titulo = slide.Shapes.AddTextbox(1, TITULO_X, TITULO_Y, TITULO_ANCHO, TITULO_ALTO)
    With titulo.TextFrame.TextRange
        .Text = texto
        .Font.Name = "Calibri"
        .Font.Size = 28
        .Font.Bold = True
        .Font.Color.RGB = RGB(0, 114, 124)
        .ParagraphFormat.Alignment = 2
    End With
End Sub

Private Sub AplicarFondo(ByVal slide As Object)
    slide.FollowMasterBackground = False
    slide.Background.Fill.Solid
    slide.Background.Fill.ForeColor.RGB = RGB(255, 255, 255)
End Sub

Private Sub AgregarLeyendaFases(ByVal slide As Object)
    Dim elementos(0 To 5) As String
    Const LEYENDA_X As Single = 28

    elementos(0) = AgregarMuestraLeyenda(slide, LEYENDA_X, 442.5558, RGB(78, 167, 46))
    elementos(1) = AgregarMuestraLeyenda(slide, LEYENDA_X, 462.3439, RGB(255, 153, 0))
    elementos(2) = AgregarMuestraLeyenda(slide, LEYENDA_X, 480.0171, RGB(255, 0, 0))
    elementos(3) = AgregarTextoLeyenda(slide, LEYENDA_X + 17.0395, 437.4508, _
        "Fase de planeaci" & ChrW(243) & "n")
    elementos(4) = AgregarTextoLeyenda(slide, LEYENDA_X + 17.0395, 458.3228, _
        "Fase de desarrollo")
    elementos(5) = AgregarTextoLeyenda(slide, LEYENDA_X + 17.7829, 475.5359, _
        "Fase de pruebas")

    ' En la diapositiva de referencia los seis objetos forman un solo grupo.
    slide.Shapes.Range(elementos).Group
End Sub

Private Function AgregarMuestraLeyenda(ByVal slide As Object, ByVal x As Single, ByVal y As Single, _
    ByVal colorFase As Long) As String
    Dim muestra As Object

    Set muestra = slide.Shapes.AddShape(1, x, y, 21.52583, 7.672284)
    muestra.Fill.Visible = True
    muestra.Fill.Solid
    muestra.Fill.ForeColor.RGB = colorFase
    muestra.Fill.Transparency = 0
    muestra.Line.Visible = True
    muestra.Line.ForeColor.RGB = colorFase
    muestra.Line.Transparency = 0

    AgregarMuestraLeyenda = muestra.Name
End Function

Private Function AgregarTextoLeyenda(ByVal slide As Object, ByVal x As Single, ByVal y As Single, _
    ByVal texto As String) As String
    Dim etiqueta As Object

    Set etiqueta = slide.Shapes.AddTextbox(1, x, y, 95.33244, 16.96409)
    With etiqueta.TextFrame.TextRange
        .Text = texto
        .Font.Name = "Aptos"
        .Font.Size = 8
        .Font.Bold = False
        .Font.Color.RGB = RGB(0, 0, 0)
        .ParagraphFormat.Alignment = 1
        .ParagraphFormat.SpaceBefore = 0
        .ParagraphFormat.SpaceAfter = 0
        .ParagraphFormat.SpaceWithin = 1
    End With
    etiqueta.Fill.Visible = False
    etiqueta.Line.Visible = False
    etiqueta.TextFrame.MarginLeft = 7.2
    etiqueta.TextFrame.MarginRight = 7.2
    etiqueta.TextFrame.MarginTop = 3.6
    etiqueta.TextFrame.MarginBottom = 3.6
    etiqueta.TextFrame.VerticalAnchor = 1
    etiqueta.TextFrame.WordWrap = True
    etiqueta.TextFrame.AutoSize = 1
    etiqueta.Left = x
    etiqueta.Top = y
    etiqueta.Width = 95.33244
    etiqueta.Height = 16.96409

    AgregarTextoLeyenda = etiqueta.Name
End Function

Private Sub AgregarAvisoConfidencialidad(ByVal slide As Object)
    Dim aviso As Object

    Set aviso = slide.Shapes.AddTextbox(1, 0, 500.5, slide.Parent.PageSetup.SlideWidth, 28.75)
    With aviso.TextFrame.TextRange
        .Text = TextoAvisoConfidencialidad()
        .Font.Name = "Calibri"
        .Font.Size = 10
        .Font.Bold = False
        .Font.Color.RGB = RGB(0, 0, 0)
        .ParagraphFormat.Alignment = 2
        .ParagraphFormat.SpaceBefore = 0
        .ParagraphFormat.SpaceAfter = 0
        .ParagraphFormat.SpaceWithin = 1
    End With
    aviso.Fill.Visible = False
    aviso.Line.Visible = False
    aviso.TextFrame.MarginLeft = 7.2
    aviso.TextFrame.MarginRight = 7.2
    aviso.TextFrame.MarginTop = 3.6
    aviso.TextFrame.MarginBottom = 3.6
    aviso.TextFrame.VerticalAnchor = 3
    aviso.TextFrame.WordWrap = True
    aviso.TextFrame.AutoSize = 0
    aviso.Left = 0
    aviso.Top = 500.5
    aviso.Width = slide.Parent.PageSetup.SlideWidth
    aviso.Height = 28.75
End Sub

Private Function TextoAvisoConfidencialidad() As String
    TextoAvisoConfidencialidad = "Informaci" & ChrW(243) & "n cuyo acceso est" & ChrW(225) & _
        " restringido a cualquier persona empleada por el Banco de M" & ChrW(233) & _
        "xico y, en su caso, personas ajenas al mismo."
End Function

Private Sub AgregarLineaBase(ByVal slide As Object, ByVal x As Single, ByVal y As Single, ByVal ancho As Single)
    Dim linea As Object

    Set linea = slide.Shapes.AddShape(1, x, y - (LINEA_GROSOR / 2), ancho, LINEA_GROSOR)
    linea.Fill.ForeColor.RGB = RGB(21, 96, 130)
    linea.Line.Visible = False
End Sub

Private Function FechaLargaEspanol(ByVal fecha As Date) As String
    FechaLargaEspanol = Format$(Day(fecha), "00") & " de " & NombreMes(Month(fecha)) & " de " & Year(fecha)
End Function

Private Function NombreMes(ByVal numeroMes As Long) As String
    Select Case numeroMes
        Case 1: NombreMes = "enero"
        Case 2: NombreMes = "febrero"
        Case 3: NombreMes = "marzo"
        Case 4: NombreMes = "abril"
        Case 5: NombreMes = "mayo"
        Case 6: NombreMes = "junio"
        Case 7: NombreMes = "julio"
        Case 8: NombreMes = "agosto"
        Case 9: NombreMes = "septiembre"
        Case 10: NombreMes = "octubre"
        Case 11: NombreMes = "noviembre"
        Case 12: NombreMes = "diciembre"
    End Select
End Function

Private Function ColorPorFase(ByVal faseEvento As String) As Long
    Select Case LCase$(Trim$(QuitarAcentos(NormalizarFase(faseEvento))))
        Case "planeacion"
            ColorPorFase = RGB(78, 167, 46)
        Case "desarrollo"
            ColorPorFase = RGB(255, 153, 0)
        Case "pruebas"
            ColorPorFase = RGB(255, 0, 0)
        Case Else
            ColorPorFase = RGB(21, 96, 130)
    End Select
End Function

Private Function ColorFondoPorFase(ByVal faseEvento As String) As Long
    Select Case LCase$(Trim$(QuitarAcentos(NormalizarFase(faseEvento))))
        Case "planeacion"
            ColorFondoPorFase = RGB(226, 239, 218)
        Case "desarrollo"
            ColorFondoPorFase = RGB(255, 242, 204)
        Case "pruebas"
            ColorFondoPorFase = RGB(244, 221, 221)
        Case Else
            ColorFondoPorFase = RGB(221, 235, 247)
    End Select
End Function

Private Function EsFaseEventoVisual(ByVal faseEvento As String) As Boolean
    EsFaseEventoVisual = (NormalizarFase(faseEvento) <> vbNullString)
End Function

Private Function ContarEventosVisuales(ByVal ws As Worksheet) As Long
    Dim ultimaFila As Long
    Dim fila As Long

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    For fila = 2 To ultimaFila
        If EsFaseEventoVisual(CStr(ws.Cells(fila, COL_EVENTO_FASE).Value)) Then
            ContarEventosVisuales = ContarEventosVisuales + 1
        End If
    Next fila
End Function

Private Function FilasEventosVisuales(ByVal ws As Worksheet, ByVal totalEventos As Long) As Variant
    Dim ultimaFila As Long
    Dim fila As Long
    Dim contador As Long
    Dim filas() As Long

    ReDim filas(1 To totalEventos)
    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    For fila = 2 To ultimaFila
        If EsFaseEventoVisual(CStr(ws.Cells(fila, COL_EVENTO_FASE).Value)) Then
            contador = contador + 1
            filas(contador) = fila
            If contador = totalEventos Then Exit For
        End If
    Next fila

    FilasEventosVisuales = filas
End Function

Private Function QuitarAcentos(ByVal texto As String) As String
    texto = Replace(texto, ChrW(225), "a")
    texto = Replace(texto, ChrW(233), "e")
    texto = Replace(texto, ChrW(237), "i")
    texto = Replace(texto, ChrW(243), "o")
    texto = Replace(texto, ChrW(250), "u")
    QuitarAcentos = texto
End Function

Private Function SoloDigitos(ByVal texto As String) As String
    Dim i As Long
    Dim caracter As String

    For i = 1 To Len(texto)
        caracter = Mid$(texto, i, 1)
        If caracter Like "#" Then SoloDigitos = SoloDigitos & caracter
    Next i
End Function

Private Function MesDesdeTexto(ByVal texto As String) As Long
    texto = Left$(LCase$(QuitarAcentos(texto)), 3)

    Select Case texto
        Case "ene": MesDesdeTexto = 1
        Case "feb": MesDesdeTexto = 2
        Case "mar": MesDesdeTexto = 3
        Case "abr": MesDesdeTexto = 4
        Case "may": MesDesdeTexto = 5
        Case "jun": MesDesdeTexto = 6
        Case "jul": MesDesdeTexto = 7
        Case "ago": MesDesdeTexto = 8
        Case "sep": MesDesdeTexto = 9
        Case "oct": MesDesdeTexto = 10
        Case "nov": MesDesdeTexto = 11
        Case "dic": MesDesdeTexto = 12
    End Select
End Function
