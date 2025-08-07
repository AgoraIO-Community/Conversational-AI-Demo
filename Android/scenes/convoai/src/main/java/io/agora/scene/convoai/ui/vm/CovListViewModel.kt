package io.agora.scene.convoai.ui.vm

import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import io.agora.scene.convoai.CovLogger
import io.agora.scene.convoai.api.CovAgentApiManager
import io.agora.scene.convoai.api.CovAgentPreset
import io.agora.scene.convoai.constant.CovAgentManager
import kotlinx.coroutines.launch

/**
 * ViewModel for managing agent list data (official and custom agents)
 * Handles data fetching, state management, and provides unified interface for fragments
 */
class CovListViewModel : ViewModel() {

    private val TAG = "CovListViewModel"

    // Data storage
    private val _officialAgents = MutableLiveData<List<CovAgentPreset>>()
    val officialAgents: LiveData<List<CovAgentPreset>> = _officialAgents

    private val _customAgents = MutableLiveData<List<CovAgentPreset>>()
    val customAgents: LiveData<List<CovAgentPreset>> = _customAgents

    // State management
    private val _officialState = MutableLiveData<AgentListState>()
    val officialState: LiveData<AgentListState> = _officialState

    private val _customState = MutableLiveData<AgentListState>()
    val customState: LiveData<AgentListState> = _customState

    init {
        // Initialize with empty data and states
        _officialAgents.value = emptyList()
        _customAgents.value = emptyList()
        _officialState.value = AgentListState.Empty
        _customState.value = AgentListState.Empty
    }

    /**
     * Unified state for agent list loading, error, and empty states
     */
    sealed class AgentListState {
        object Loading : AgentListState()
        object Success : AgentListState()
        data class Error(val message: String) : AgentListState()
        object Empty : AgentListState()
    }

    /**
     * Load official agent presets from API or mock data
     */
    fun loadOfficialAgents() {
        viewModelScope.launch {
            try {
                CovLogger.d(TAG, "Loading official agents...")
                _officialState.value = AgentListState.Loading

                if (CovAgentManager.isOpenSource) {
                    // Use mock data for open source mode
                    val mockPresets = createMockOfficialAgents()
                    CovLogger.d(TAG, "Using mock data for open source mode: ${mockPresets.size} items")
                    _officialAgents.value = mockPresets
                    _officialState.value = if (mockPresets.isEmpty()) {
                        AgentListState.Empty
                    } else {
                        AgentListState.Success
                    }
                } else {
                    // Use real API for production mode
                    CovAgentApiManager.fetchPresets { error, presets ->
                        if (error != null) {
                            CovLogger.e(TAG, "Failed to load official presets: ${error.message}")
                            _officialState.value = AgentListState.Error("")
                        } else {
                            CovLogger.d(TAG, "Official agents loaded: ${presets.size} items")
                            _officialAgents.value = presets
                            _officialState.value = if (presets.isEmpty()) {
                                AgentListState.Empty
                            } else {
                                AgentListState.Success
                            }
                        }
                    }
                }
            } catch (e: Exception) {
                CovLogger.e(TAG, "Exception loading official agents: ${e.message}")
                _officialState.value = AgentListState.Error("")
            }
        }
    }

    /**
     * Create mock official agents for open source mode
     */
    private fun createMockOfficialAgents(): List<CovAgentPreset> {
        return listOf(
            CovAgentPreset(
                index = 0,
                name = "Mock Assistant",
                display_name = "AI Assistant",
                description = "A helpful AI assistant for general conversations",
                avatar_url = "https://example.com/avatar1.png",
                preset_type = "official",
                default_language_code = "",
                default_language_name = "",
                support_languages = emptyList(),
                call_time_limit_second = 600L,
                call_time_limit_avatar_second = 300L,
                is_support_vision = true
            )
        )
    }

    /**
     * Load custom agent presets
     * @param customPresetIds Comma-separated list of custom preset IDs (e.g., "p1,p2,p3")
     */
    fun loadCustomAgents(customPresetIds: String = "") {
        viewModelScope.launch {
            try {
                _customState.value = AgentListState.Loading
                CovAgentApiManager.fetchCustomsPresets(customPresetIds) { error, presets ->
                    if (error != null) {
                        CovLogger.e(TAG, "Failed to load custom presets: ${error.message}")
                        _customState.value = AgentListState.Error("")
                    } else {
                        _customAgents.value = presets
                        _customState.value = if (presets.isEmpty()) {
                            AgentListState.Empty
                        } else {
                            AgentListState.Success
                        }
                    }
                }

            } catch (e: Exception) {
                CovLogger.e(TAG, "Exception loading custom agents: ${e.message}")
                _customState.value = AgentListState.Error("")
            }
        }
    }

    /**
     * Refresh both official and custom agents
     * @param customPresetIds Comma-separated list of custom preset IDs
     */
    fun refreshAllAgents(customPresetIds: String = "") {
        loadOfficialAgents()
        loadCustomAgents(customPresetIds)
    }

    /**
     * Clear error states
     */
    fun clearOfficialError() {
        if (_officialState.value is AgentListState.Error) {
            _officialState.value = AgentListState.Empty
        }
    }

    fun clearCustomError() {
        if (_customState.value is AgentListState.Error) {
            _customState.value = AgentListState.Empty
        }
    }

    /**
     * Get agent by name from custom agents
     * This can be used when user inputs an agent ID
     */
    fun getCustomAgentByName(agentName: String): CovAgentPreset? {
        return _customAgents.value?.find { it.name == agentName }
    }

    /**
     * Check if agent name exists in custom agents
     */
    fun isCustomAgentValid(agentName: String): Boolean {
        return _customAgents.value?.any { it.name == agentName } == true
    }
} 