package io.agora.scene.convoai.iot

import com.elvishew.xlog.XLog
import com.elvishew.xlog.printer.Printer
import io.agora.scene.common.constant.AgentScenes
import io.agora.scene.common.util.AgoraLogger

internal object CovLogger {

    private val printers: List<Printer> by lazy {
        AgoraLogger.getPrinter(AgentScenes.ConvoAiIot)
    }

    fun v(tag: String, message: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .v(message)
    }

    fun d(tag: String, message: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .d(message)
    }

    fun i(tag: String, message: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .i(message)
    }

    fun w(tag: String, message: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .w(message)
    }

    fun e(tag: String, message: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .e(message)
    }

    fun json(tag: String, json: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .json(json)
    }

    fun xml(tag: String, xml: String) {
        XLog.tag(tag)
            .printers(*printers.toTypedArray())
            .xml(xml)
    }
}