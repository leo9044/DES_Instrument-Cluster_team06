"""
Instrument Cluster Display Module for PiRacer
Handles OLED display and future Qt GUI
"""

from PIL import Image, ImageDraw, ImageFont
from typing import Optional
import time


class OLEDDisplay:
    """OLED 디스플레이 제어 클래스"""
    
    def __init__(self, piracer_display):
        """
        Initialize OLED display
        
        Args:
            piracer_display: PiRacer의 디스플레이 객체
        """
        self.display = piracer_display
        self.width = 128
        self.height = 32
        
        # 폰트 설정
        try:
            self.font = ImageFont.load_default()
        except:
            self.font = None
        
        # 디스플레이 업데이트 간격 제어
        self.last_update = 0
        self.update_interval = 0.5  # 0.5초마다 업데이트
        
    def should_update(self) -> bool:
        """디스플레이 업데이트가 필요한지 확인"""
        current_time = time.time()
        if current_time - self.last_update >= self.update_interval:
            self.last_update = current_time
            return True
        return False
    
    def update_display(self, speed: float, gear: str, can_connected: bool = False):
        """
        계기판 디스플레이 업데이트
        
        Args:
            speed: 속도 (km/h)
            gear: 현재 기어
            can_connected: CAN 연결 상태
        """
        try:
            # 이미지 생성
            image = Image.new('1', (self.width, self.height))
            draw = ImageDraw.Draw(image)
        
            # 레이아웃:
            # 상단: 속도 및 기어 정보
            # 하단: CAN 상태
            
            try:
                # 상단: 속도 및 기어 (첫 번째 줄)
                speed_text = f"Speed: {speed:.1f}km/h"
                gear_text = f"Gear: {gear}"
                
                self._draw_text(draw, (2, 0), speed_text, self.font)
                self._draw_text(draw, (70, 0), gear_text, self.font)
                
                # 하단: CAN 상태 (세 번째 줄)
                can_status = "CAN: OK" if can_connected else "CAN: OFF"
                self._draw_text(draw, (2, 21), can_status, self.font)
                
            except Exception as e:
                # 폰트 오류시 기본 텍스트로 표시
                draw.text((2, 0), speed_text, fill=1)
                draw.text((70, 0), gear_text, fill=1)
                draw.text((2, 21), can_status, fill=1)
        
            # 화면에 표시
            self.display.image(image)
            self.display.show()
        except Exception as e:
            print(f"OLED 디스플레이 업데이트 오류: {e}")
    
    def _draw_text(self, draw, position, text, font):
        """텍스트 그리기 (폰트 오류 처리 포함)"""
        try:
            if font:
                draw.text(position, text, font=font, fill=1)
            else:
                draw.text(position, text, fill=1)
        except:
            draw.text(position, text, fill=1)
    
    def show_startup_message(self):
        """시작 메시지 표시"""
        try:
            image = Image.new('1', (self.width, self.height))
            draw = ImageDraw.Draw(image)
            
            self._draw_text(draw, (10, 5), "PiRacer Cluster", self.font)
            self._draw_text(draw, (20, 18), "Starting...", self.font)
            
            self.display.image(image)
            self.display.show()
        except Exception as e:
            print(f"시작 메시지 표시 오류: {e}")
    
    def show_error_message(self, message: str):
        """에러 메시지 표시"""
        try:
            image = Image.new('1', (self.width, self.height))
            draw = ImageDraw.Draw(image)
            
            self._draw_text(draw, (5, 5), "ERROR:", self.font)
            self._draw_text(draw, (5, 18), message[:18], self.font)  # 화면 크기에 맞게 자르기
            
            self.display.image(image)
            self.display.show()
        except Exception as e:
            print(f"에러 메시지 표시 오류: {e}")


class InstrumentClusterDisplay:
    """계기판 디스플레이 통합 관리 클래스"""
    
    def __init__(self, piracer_display):
        """
        Initialize instrument cluster display
        
        Args:
            piracer_display: PiRacer의 디스플레이 객체
        """
        self.oled = OLEDDisplay(piracer_display)
        # 미래에 Qt GUI가 추가될 예정
        self.qt_gui = None
    
    def show_startup(self):
        """시작 화면 표시"""
        self.oled.show_startup_message()
        time.sleep(2)  # 2초간 표시
    
    def update(self, speed: float, gear: str, can_connected: bool):
        """
        모든 디스플레이 업데이트
        
        Args:
            speed: 현재 속도
            gear: 기어 상태
            can_connected: CAN 연결 상태
        """
        # OLED 업데이트
        self.oled.update_display(speed, gear, can_connected)
        
        # Qt GUI 업데이트 (미래에 추가될 예정)
        if self.qt_gui:
            self.qt_gui.update_display(speed, gear, can_connected)
    
    def show_error(self, message: str):
        """에러 메시지 표시"""
        self.oled.show_error_message(message)


if __name__ == '__main__':
    """테스트용 메인 함수"""
    print("📱 Display Module Test")
    print("OLED 디스플레이가 연결되어 있어야 테스트할 수 있습니다.")
    
    # 실제 테스트를 위해서는 PiRacer 하드웨어가 필요
    # 여기서는 구조만 확인