Attribute VB_Name = "modLineaTiempo"
Option Explicit

' Configuracion principal del libro.
Private Const HOJA_REGISTRAR As String = "Registrar"
Private Const HOJA_EVENTOS As String = "Eventos"

' Columnas de la hoja Eventos.
Private Const COL_EVENTO_ID As String = "A"
Private Const COL_EVENTO_FECHA As String = "B"
Private Const COL_EVENTO_TIPO As String = "C"
Private Const COL_EVENTO_COMENTARIO As String = "D"

' Configuracion de PowerPoint.
Private Const ARCHIVO_POWERPOINT_SALIDA As String = "Linea del Tiempo.pptx"
Private Const EVENTOS_POR_DIAPOSITIVA As Long = 5
Private Const DIAPO_PORTADA As Long = 1
Private Const DIAPO_PRIMERA_LINEA As Long = 2
Private Const ETIQUETA_GENERADA As String = "linea_tiempo_generada"

' Medidas tomadas de la plantilla de la linea del tiempo.
Private Const TITULO_X As Single = 66
Private Const TITULO_Y As Single = 28.75
Private Const TITULO_ANCHO As Single = 828
Private Const TITULO_ALTO As Single = 38.96
Private Const LINEA_Y As Single = 270
Private Const LINEA_GROSOR As Single = 6
Private Const MARCADOR_DIAMETRO As Single = 10
Private Const CONECTOR_GROSOR As Single = 2
Private Const MAX_CARACTERES_COMENTARIO As Long = 128

Public Sub agregarALineaTiempo()
    Dim wsRegistro As Worksheet
    Dim wsEventos As Worksheet
    Dim fechaEvento As Date
    Dim tipoEvento As String
    Dim comentario As String
    Dim siguienteFila As Long
    Dim siguienteId As Long
    Dim colFecha As Long
    Dim colTipo As Long
    Dim colComentario As Long
    Dim filaEncabezado As Long
    Dim filaCaptura As Long

    Set wsRegistro = ThisWorkbook.Worksheets(HOJA_REGISTRAR)
    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)

    filaEncabezado = FilaEncabezadoFormulario(wsRegistro)
    If filaEncabezado = 0 Then
        MsgBox "No encontre los encabezados Fecha, Tipo y Comentario en la hoja Registrar.", vbExclamation, "Formulario incompleto"
        Exit Sub
    End If

    filaCaptura = filaEncabezado + 1
    colFecha = ColumnaPorEncabezado(wsRegistro, "Fecha", filaEncabezado)
    colTipo = ColumnaPorEncabezado(wsRegistro, "Tipo", filaEncabezado)
    colComentario = ColumnaPorEncabezado(wsRegistro, "Comentario", filaEncabezado)

    If Not ObtenerFechaNormalizada(wsRegistro.Cells(filaCaptura, colFecha), fechaEvento) Then
        MsgBox "Captura una fecha valida.", vbExclamation, "Evento incompleto"
        wsRegistro.Cells(filaCaptura, colFecha).Select
        Exit Sub
    End If

    tipoEvento = Trim$(CStr(wsRegistro.Cells(filaCaptura, colTipo).Value))
    comentario = Trim$(CStr(wsRegistro.Cells(filaCaptura, colComentario).Value))

    If tipoEvento = vbNullString Then
        MsgBox "Selecciona un tipo de evento.", vbExclamation, "Evento incompleto"
        wsRegistro.Cells(filaCaptura, colTipo).Select
        Exit Sub
    End If

    If comentario = vbNullString Then
        MsgBox "Escribe un comentario para el evento.", vbExclamation, "Evento incompleto"
        wsRegistro.Cells(filaCaptura, colComentario).Select
        Exit Sub
    End If

    If Len(comentario) > MAX_CARACTERES_COMENTARIO Then
        MsgBox "El comentario debe tener maximo " & MAX_CARACTERES_COMENTARIO & " caracteres.", vbExclamation, "Comentario demasiado largo"
        wsRegistro.Cells(filaCaptura, colComentario).Select
        Exit Sub
    End If

    siguienteFila = SiguienteFilaLibre(wsEventos, COL_EVENTO_ID)
    siguienteId = SiguienteIdEvento(wsEventos)

    wsEventos.Cells(siguienteFila, COL_EVENTO_ID).Value = siguienteId
    wsEventos.Cells(siguienteFila, COL_EVENTO_FECHA).Value = fechaEvento
    wsEventos.Cells(siguienteFila, COL_EVENTO_TIPO).Value = tipoEvento
    wsEventos.Cells(siguienteFila, COL_EVENTO_COMENTARIO).Value = comentario
    wsEventos.Cells(siguienteFila, COL_EVENTO_FECHA).NumberFormat = "dd/mm/yyyy"

    OrdenarEventos wsEventos
    RenumerarEventos wsEventos
    FormatearTablaEventos wsEventos
    LimpiarCaptura wsRegistro, filaCaptura, colFecha, colTipo, colComentario
    CrearLineaTiempoPowerPoint

    MsgBox "Evento agregado y presentacion actualizada.", vbInformation, "Linea del tiempo"
End Sub

Public Sub eliminarALineaTiempo()
    Dim wsEventos As Worksheet
    Dim filaEvento As Long
    Dim ultimaFila As Long
    Dim respuesta As VbMsgBoxResult
    Dim descripcionEvento As String
    Dim textoId As String
    Dim idEvento As Long

    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)
    ultimaFila = UltimaFilaConDatos(wsEventos, COL_EVENTO_ID)

    If ultimaFila < 2 Then
        MsgBox "No hay eventos para borrar.", vbExclamation, "Borrar evento"
        Exit Sub
    End If

    textoId = Trim$(InputBox("Escribe el ID del evento que quieres borrar:", "Borrar evento"))
    If textoId = vbNullString Then Exit Sub

    If Not EsEnteroPositivo(textoId) Then
        MsgBox "El ID debe ser un numero entero positivo.", vbExclamation, "ID invalido"
        Exit Sub
    End If

    idEvento = CLng(textoId)
    filaEvento = FilaPorIdEvento(wsEventos, idEvento)

    If filaEvento = 0 Then
        MsgBox "No existe un evento con el ID " & idEvento & ".", vbExclamation, "ID no encontrado"
        Exit Sub
    End If

    descripcionEvento = "ID " & idEvento & ": " & _
        CStr(wsEventos.Cells(filaEvento, COL_EVENTO_FECHA).Text) & " - " & _
        CStr(wsEventos.Cells(filaEvento, COL_EVENTO_TIPO).Value) & " - " & _
        CStr(wsEventos.Cells(filaEvento, COL_EVENTO_COMENTARIO).Value)

    respuesta = MsgBox("Se borrara este evento:" & vbCrLf & vbCrLf & descripcionEvento & vbCrLf & vbCrLf & _
        "Deseas continuar?", vbQuestion + vbYesNo, "Confirmar borrado")
    If respuesta <> vbYes Then Exit Sub

    wsEventos.Rows(filaEvento).Delete

    If UltimaFilaConDatos(wsEventos, COL_EVENTO_ID) >= 2 Then
        OrdenarEventos wsEventos
        RenumerarEventos wsEventos
        FormatearTablaEventos wsEventos
        CrearLineaTiempoPowerPoint
    Else
        FormatearTablaEventos wsEventos
        LimpiarPowerPointSinEventos
    End If

    MsgBox "Evento borrado y presentacion actualizada.", vbInformation, "Borrar evento"
End Sub

Private Sub CrearLineaTiempoPowerPoint()
    Dim wsEventos As Worksheet
    Dim ultimaFila As Long
    Dim totalEventos As Long
    Dim pptApp As Object
    Dim pptPres As Object
    Dim rutaPpt As String

    Set wsEventos = ThisWorkbook.Worksheets(HOJA_EVENTOS)

    OrdenarEventos wsEventos
    RenumerarEventos wsEventos
    FormatearTablaEventos wsEventos

    ultimaFila = UltimaFilaConDatos(wsEventos, COL_EVENTO_ID)
    If ultimaFila < 2 Then
        LimpiarPowerPointSinEventos
        Exit Sub
    End If

    totalEventos = ultimaFila - 1
    rutaPpt = RutaPowerPoint()

    Set pptApp = ObtenerPowerPoint()
    pptApp.Visible = True

    If Dir$(rutaPpt) = vbNullString Then
        If Not ConfirmarCreacionPresentacion(rutaPpt) Then Exit Sub
        Set pptPres = CrearPresentacionBase(pptApp, rutaPpt)
        MsgBox "La presentacion se creo con exito en:" & vbCrLf & vbCrLf & rutaPpt, vbInformation, "Presentacion creada"
    Else
        Set pptPres = AbrirOPresentacion(pptApp, rutaPpt)
    End If

    If pptPres.Slides.Count < DIAPO_PRIMERA_LINEA Then
        CompletarPresentacionBase pptPres
        pptPres.SaveAs rutaPpt
    End If

    EliminarDiapositivasGeneradas pptPres
    CrearDiapositivasDesdeEventos pptPres, wsEventos, totalEventos
    pptPres.Save
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
            ColumnaPorEncabezado(ws, "Tipo", fila) > 0 And _
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

Private Sub LimpiarCaptura(ByVal ws As Worksheet, ByVal filaCaptura As Long, ByVal colFecha As Long, ByVal colTipo As Long, ByVal colComentario As Long)
    ws.Cells(filaCaptura, colFecha).ClearContents
    ws.Cells(filaCaptura, colTipo).ClearContents
    ws.Cells(filaCaptura, colComentario).ClearContents
    ws.Cells(filaCaptura, colFecha).Select
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

    ultimaFila = UltimaFilaConDatos(ws, COL_EVENTO_ID)
    If ultimaFila < 1 Then ultimaFila = 1

    Set rangoLimpieza = ws.Range("A1:D" & Application.WorksheetFunction.Max(ultimaFila + 20, 50))
    rangoLimpieza.Borders.LineStyle = xlNone

    Set rangoTabla = ws.Range("A1:D" & ultimaFila)
    ws.Range("A1:D1").Value = Array("ID", "Fecha", "Tipo", "Comentario")

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
    ws.Columns("C").ColumnWidth = 12
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
    RutaPowerPoint = ThisWorkbook.Path & Application.PathSeparator & ARCHIVO_POWERPOINT_SALIDA
End Function

Private Function AbrirOPresentacion(ByVal pptApp As Object, ByVal rutaPpt As String) As Object
    Dim presentacion As Object

    For Each presentacion In pptApp.Presentations
        If StrComp(presentacion.FullName, rutaPpt, vbTextCompare) = 0 Then
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
    pptPres.SaveAs rutaPpt

    Set CrearPresentacionBase = pptPres
End Function

Private Function ConfirmarCreacionPresentacion(ByVal rutaPpt As String) As Boolean
    Dim respuesta As VbMsgBoxResult

    respuesta = MsgBox("No se encontro la presentacion." & vbCrLf & vbCrLf & _
        "Deseas crear el archivo en esta ruta?" & vbCrLf & vbCrLf & rutaPpt, _
        vbQuestion + vbYesNo, "Crear presentacion")

    ConfirmarCreacionPresentacion = (respuesta = vbYes)
End Function

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
    Dim pptPres As Object
    Dim rutaPpt As String

    rutaPpt = RutaPowerPoint()

    Set pptApp = ObtenerPowerPoint()
    pptApp.Visible = True

    If Dir$(rutaPpt) = vbNullString Then
        If Not ConfirmarCreacionPresentacion(rutaPpt) Then Exit Sub
        Set pptPres = CrearPresentacionBase(pptApp, rutaPpt)
        MsgBox "La presentacion se creo con exito en:" & vbCrLf & vbCrLf & rutaPpt, vbInformation, "Presentacion creada"
    Else
        Set pptPres = AbrirOPresentacion(pptApp, rutaPpt)
    End If

    If pptPres.Slides.Count < DIAPO_PRIMERA_LINEA Then CompletarPresentacionBase pptPres

    EliminarDiapositivasGeneradas pptPres
    LimpiarDiapositiva pptPres.Slides(DIAPO_PRIMERA_LINEA)
    AgregarTitulo pptPres.Slides(DIAPO_PRIMERA_LINEA), TituloPresentacion()
    AgregarLineaBase pptPres.Slides(DIAPO_PRIMERA_LINEA), 0, LINEA_Y, pptPres.PageSetup.SlideWidth
    pptPres.Save
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

    totalDiapositivas = Application.WorksheetFunction.RoundUp(totalEventos / EVENTOS_POR_DIAPOSITIVA, 0)

    For numeroDiapositiva = 1 To totalDiapositivas
        If numeroDiapositiva = 1 Then
            Set slideActual = pptPres.Slides(DIAPO_PRIMERA_LINEA)
            LimpiarDiapositiva slideActual
        Else
            Set slideActual = CrearDiapositivaGenerada(pptPres)
        End If

        DibujarDiapositivaEventos slideActual, ws, numeroDiapositiva, totalEventos
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

Private Sub DibujarDiapositivaEventos(ByVal slide As Object, ByVal ws As Worksheet, ByVal numeroDiapositiva As Long, ByVal totalEventos As Long)
    Dim slot As Long
    Dim indiceEvento As Long
    Dim filaEvento As Long
    Dim fechaTexto As String
    Dim tipoEvento As String
    Dim comentario As String
    Dim x As Single
    Dim estaArriba As Boolean

    AgregarTitulo slide, TituloPresentacion()
    AgregarLineaBase slide, 0, LINEA_Y, slide.Parent.PageSetup.SlideWidth

    For slot = 1 To EVENTOS_POR_DIAPOSITIVA
        indiceEvento = ((numeroDiapositiva - 1) * EVENTOS_POR_DIAPOSITIVA) + slot

        If indiceEvento <= totalEventos Then
            filaEvento = indiceEvento + 1
            x = PosicionEventoX(slot)
            estaArriba = EventoVaArriba(numeroDiapositiva, slot)
            fechaTexto = FechaLargaEspanol(ws.Cells(filaEvento, COL_EVENTO_FECHA).Value)
            tipoEvento = CStr(ws.Cells(filaEvento, COL_EVENTO_TIPO).Value)
            comentario = CStr(ws.Cells(filaEvento, COL_EVENTO_COMENTARIO).Value)

            AgregarEventoPowerPoint slide, x, LINEA_Y, estaArriba, fechaTexto, tipoEvento, comentario
        End If
    Next slot
End Sub

Private Function PosicionEventoX(ByVal slot As Long) As Single
    Select Case slot
        Case 1: PosicionEventoX = 96
        Case 2: PosicionEventoX = 288
        Case 3: PosicionEventoX = 480
        Case 4: PosicionEventoX = 672
        Case 5: PosicionEventoX = 864
    End Select
End Function

Private Function TituloPresentacion() As String
    TituloPresentacion = "L" & ChrW(237) & "nea del tiempo de para la integraci" & ChrW(243) & "n de plataformas GPS con el PSIM"
End Function

Private Function EventoVaArriba(ByVal numeroDiapositiva As Long, ByVal slot As Long) As Boolean
    If numeroDiapositiva Mod 2 = 1 Then
        EventoVaArriba = (slot Mod 2 = 1)
    Else
        EventoVaArriba = (slot Mod 2 = 0)
    End If
End Function

Private Sub AgregarEventoPowerPoint(ByVal slide As Object, ByVal x As Single, ByVal yLinea As Single, ByVal estaArriba As Boolean, ByVal fechaTexto As String, ByVal tipoEvento As String, ByVal comentario As String)
    Dim yMarcador As Single
    Dim yFecha As Single
    Dim yComentario As Single
    Dim altoConector As Single
    Dim conector As Object
    Dim marcador As Object
    Dim fechaBox As Object
    Dim comentarioBox As Object
    Dim yConector As Single
    Dim altoRealConector As Single
    Dim altoComentario As Single
    Dim anchoComentario As Single

    altoConector = 102
    anchoComentario = 138
    altoComentario = AltoTextoComentario(comentario)

    If estaArriba Then
        yMarcador = yLinea - altoConector
        yFecha = yLinea + 17
        yComentario = yMarcador - 14 - altoComentario
        yConector = yMarcador
        altoRealConector = (yLinea - (LINEA_GROSOR / 2)) - yMarcador
    Else
        yMarcador = yLinea + altoConector
        yFecha = yLinea - 33
        yComentario = yMarcador + 18
        yConector = yLinea + (LINEA_GROSOR / 2)
        altoRealConector = yMarcador - yConector
    End If

    Set conector = slide.Shapes.AddShape(1, x - (CONECTOR_GROSOR / 2), yConector, CONECTOR_GROSOR, altoRealConector)
    conector.Fill.ForeColor.RGB = ColorPorTipo(tipoEvento)
    conector.Line.Visible = False

    Set marcador = slide.Shapes.AddShape(9, x - (MARCADOR_DIAMETRO / 2), yMarcador - (MARCADOR_DIAMETRO / 2), MARCADOR_DIAMETRO, MARCADOR_DIAMETRO)
    marcador.Fill.ForeColor.RGB = RGB(255, 255, 255)
    marcador.Line.ForeColor.RGB = ColorPorTipo(tipoEvento)
    marcador.Line.Weight = 2.25

    Set fechaBox = slide.Shapes.AddTextbox(1, x - 69, yFecha, 138, 22)
    With fechaBox.TextFrame.TextRange
        .Text = fechaTexto
        .Font.Name = "Calibri"
        .Font.Size = 11
        .Font.Bold = True
        .Font.Color.RGB = RGB(20, 20, 20)
        .ParagraphFormat.Alignment = 2
    End With

    Set comentarioBox = slide.Shapes.AddTextbox(1, x - (anchoComentario / 2), yComentario, anchoComentario, altoComentario)
    With comentarioBox.TextFrame.TextRange
        .Text = comentario
        .Font.Name = "Calibri"
        .Font.Size = 12
        .Font.Bold = False
        .Font.Color.RGB = RGB(30, 30, 30)
        .ParagraphFormat.Alignment = 2
    End With
End Sub

Private Function AltoTextoComentario(ByVal texto As String) As Single
    Dim lineas As Long

    lineas = Application.WorksheetFunction.RoundUp((Len(texto) + 1) / 18, 0)
    If lineas < 1 Then lineas = 1
    If lineas > 5 Then lineas = 5

    AltoTextoComentario = 16 + (lineas * 14)
End Function

Private Sub AgregarTitulo(ByVal slide As Object, ByVal texto As String)
    Dim titulo As Object

    Set titulo = slide.Shapes.AddTextbox(1, TITULO_X, TITULO_Y, TITULO_ANCHO, TITULO_ALTO)
    With titulo.TextFrame.TextRange
        .Text = texto
        .Font.Name = "Calibri"
        .Font.Size = 18
        .Font.Bold = True
        .Font.Color.RGB = RGB(0, 0, 0)
        .ParagraphFormat.Alignment = 2
    End With
End Sub

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

Private Function ColorPorTipo(ByVal tipoEvento As String) As Long
    Select Case LCase$(Trim$(tipoEvento))
        Case "verde"
            ColorPorTipo = RGB(34, 197, 94)
        Case "naranja"
            ColorPorTipo = RGB(249, 115, 22)
        Case "rojo"
            ColorPorTipo = RGB(239, 68, 68)
        Case Else
            ColorPorTipo = RGB(59, 130, 246)
    End Select
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
