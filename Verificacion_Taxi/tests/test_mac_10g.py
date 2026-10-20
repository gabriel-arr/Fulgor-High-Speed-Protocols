@cocotb.test()
#async le indica que puede esperar eventos de la simulacion con await
async def test_mac_tx_01_basic(dut):
    #creamos el entorno de test alrededor del modulo hdl
    tb = TB(dut)

    # Configuración básica del transmisor
    dut.cfg_tx_pad_en.value = 1             #habilita el padding
    dut.cfg_tx_min_pkt_len.value = 60-1     #establece el tamaño minimo de paquete
    dut.cfg_tx_max_pkt_len.value = 1518-1   #establece el tamaño maximo de paquete
    dut.cfg_tx_ifg.value = 12               #inter frame gap, separacion entre los frames 
    dut.cfg_tx_enable.value = 1             #habilita la transmision 

    await tb.reset()                        #ejecutamos el reset del hdl 

    # Frame Ethernet de prueba de 60 bytes
    test_data = bytes(range(60))

    # DRIVER:
    # enviamos el frame al MAC mediante AXI Stream
    await tb.axis_source.send(
        AxiStreamFrame(test_data, tid=0, tuser=0)   #crea una transaccion axi stream
                                                    #test_data nuestros 60 bytes, tid y tuser parametros de axi
    )

    # MONITOR:
    # esperamos la trama completa, generada en XGMII
    rx_frame = await tb.xgmii_sink.recv() 

    # El MAC también genera una notificación de TX completado
    await tb.tx_cpl_sink.recv()

    # CHECKERS
    assert rx_frame.get_payload() == test_data  #comprobamos que lo recibido sea igual a lo que enviamos
    assert rx_frame.check_fcs()                 #comprueba que el fcs sea valido 
    assert rx_frame.ctrl is None                #no hay condicion/control inesperado en la trama recibida

    dut._log.info("MAC-TX-01 PASS")