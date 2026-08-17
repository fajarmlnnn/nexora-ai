<?php

namespace Tests\Unit;

use Tests\TestCase;

class AiTonePolicyTest extends TestCase
{
    public function test_system_prompt_has_gen_z_tone_policy(): void
    {
        $path = base_path('app/Services/Ai/AiTonePolicy.php');
        $source = file_get_contents($path);

        $this->assertNotFalse($source);
        $this->assertStringContainsString('Gen Z', $source);
        $this->assertStringContainsString('natural', $source);
        $this->assertStringContainsString('casual', $source);
        $this->assertStringContainsString('Indonesian', $source);
        $this->assertStringNotContainsString('kamu', strtolower($source));
    }
}
